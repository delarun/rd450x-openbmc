// IPMI handlers for what the RD450X host firmware sends to its BMC.
//
// The BIOS in use on this board is built from a Supermicro X10DRX BIOS and
// talks the Supermicro "out of band" dialect (NetFn 0x30, command 0xA0) to
// hand files to the BMC before the OS starts. The protocol below was read
// from the BIOS modules SmcFullSM, SmcAssetInfo and SmcDevReport:
//
//   A0 20 <query>                    does the BMC hold this file already?
//   A0 26 <type> <size:u32>          start an upload
//   A0 27 <type> <offset:u32> <data> one chunk (64 bytes from the BIOS)
//   A0 28 <type>                     finish; reply 0 = busy, 1 = error
//
//   type 1 (query 4)  SMBIOS structure table behind a 16 byte "_SM_" header
//   type 2 (query 5)  device report
//   type 4 (query 8)  asset information
//
// Every reply is a single byte: the BIOS passes a one byte buffer.
// The other sub-commands (0x22/0x24 in SmcOutBand, which look like downloads
// from the BMC) are deliberately left unanswered.

#include <ipmid/api.hpp>
#include <phosphor-logging/lg2.hpp>
#include <sdbusplus/bus.hpp>

#include <array>
#include <cstdint>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <map>
#include <numeric>
#include <optional>
#include <string>
#include <vector>

namespace rd450x
{

namespace fs = std::filesystem;

constexpr ipmi::Cmd cmdSmcOob = 0xa0;

constexpr uint8_t subQuery = 0x20;
constexpr uint8_t subStart = 0x26;
constexpr uint8_t subData = 0x27;
constexpr uint8_t subFinish = 0x28;

constexpr uint8_t typeSmbios = 1;
constexpr uint8_t finishOk = 2;
constexpr uint8_t finishError = 1;

constexpr size_t maxUpload = 64 * 1024;
constexpr const char* storeDir = "/var/lib/rd450x-oob";

// smbios-mdr reads its tables from this file (see smbios_mdrv2.hpp).
constexpr const char* mdrFile = "/var/lib/smbios/smbios2";
constexpr const char* mdrService = "xyz.openbmc_project.Smbios.MDR_V2";
constexpr const char* mdrPath = "/xyz/openbmc_project/Smbios/MDR_V2";

static std::map<uint8_t, std::vector<uint8_t>> uploads;

static std::optional<uint8_t> typeOfQuery(uint8_t query)
{
    switch (query)
    {
        case 0x04:
            return 1;
        case 0x05:
            return 2;
        case 0x08:
            return 4;
    }
    return std::nullopt;
}

static fs::path storePath(uint8_t type)
{
    return fs::path(storeDir) / ("type-" + std::to_string(type) + ".bin");
}

static std::vector<uint8_t> readFile(const fs::path& path)
{
    std::ifstream in(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(in),
            std::istreambuf_iterator<char>()};
}

static bool writeFile(const fs::path& path, const std::vector<uint8_t>& data)
{
    std::error_code ec;
    fs::create_directories(path.parent_path(), ec);
    fs::path tmp = path;
    tmp += ".tmp";
    {
        std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
        out.write(reinterpret_cast<const char*>(data.data()), data.size());
        if (!out.good())
        {
            return false;
        }
    }
    fs::rename(tmp, path, ec);
    return !ec;
}

// Turn the BIOS upload into the image smbios-mdr expects: its own 10 byte
// header, a 64-bit entry point whose table address is the offset of the
// table inside the image, then the structure table.
static bool publishSmbios(const std::vector<uint8_t>& upload)
{
    constexpr size_t smcHeader = 16;
    if (upload.size() <= smcHeader || upload[0] != '_' || upload[1] != 'S' ||
        upload[2] != 'M' || upload[3] != '_')
    {
        lg2::error("SMBIOS upload from the BIOS has no _SM_ header");
        return false;
    }
    size_t tableLen = upload[6] | (upload[7] << 8);
    if (tableLen == 0 || smcHeader + tableLen > upload.size())
    {
        lg2::error("SMBIOS upload from the BIOS is truncated");
        return false;
    }
    uint8_t sum = std::accumulate(upload.begin() + smcHeader,
                                  upload.begin() + smcHeader + tableLen,
                                  uint8_t{0});
    if (sum != upload[8])
    {
        lg2::error("SMBIOS upload from the BIOS fails its checksum");
        return false;
    }

    std::array<uint8_t, 24> ep{'_', 'S', 'M', '3', '_', 0, 24, 3, 0, 0, 1, 0};
    for (int i = 0; i < 4; i++)
    {
        ep[12 + i] = (tableLen >> (8 * i)) & 0xff;
    }
    ep[16] = ep.size(); // table address, low byte of a u64
    ep[5] = -std::accumulate(ep.begin(), ep.end(), uint8_t{0});

    uint32_t now = std::time(nullptr);
    uint32_t dataSize = ep.size() + tableLen;
    std::vector<uint8_t> image{1 /* dir version */, 2 /* MDR type II */};
    for (uint32_t v : {now, dataSize})
    {
        for (int i = 0; i < 4; i++)
        {
            image.push_back((v >> (8 * i)) & 0xff);
        }
    }
    image.insert(image.end(), ep.begin(), ep.end());
    image.insert(image.end(), upload.begin() + smcHeader,
                 upload.begin() + smcHeader + tableLen);

    if (!writeFile(mdrFile, image))
    {
        lg2::error("cannot write the SMBIOS tables for smbios-mdr");
        return false;
    }
    try
    {
        sdbusplus::bus_t bus(ipmid_get_sd_bus_connection());
        auto call = bus.new_method_call(mdrService, mdrPath, mdrService,
                                        "AgentSynchronizeData");
        bool ok = false;
        bus.call(call).read(ok);
        if (!ok)
        {
            lg2::error("smbios-mdr refused the tables sent by the BIOS");
        }
        return ok;
    }
    catch (const std::exception& e)
    {
        lg2::error("cannot reach smbios-mdr: {ERROR}", "ERROR", e.what());
        return false;
    }
}

static uint8_t finish(uint8_t type)
{
    auto it = uploads.find(type);
    if (it == uploads.end())
    {
        return finishError;
    }
    std::vector<uint8_t> data = std::move(it->second);
    uploads.erase(it);

    // The writable flash is small and wears: only rewrite on a change.
    fs::path path = storePath(type);
    bool changed = readFile(path) != data;
    if (changed && !writeFile(path, data))
    {
        lg2::error("cannot store BIOS upload type {TYPE}", "TYPE", type);
        return finishError;
    }
    lg2::info("BIOS upload type {TYPE}: {SIZE} bytes{NOTE}", "TYPE", type,
              "SIZE", data.size(), "NOTE", changed ? "" : " (unchanged)");
    if (type == typeSmbios && changed && !publishSmbios(data))
    {
        std::error_code ec;
        fs::remove(path, ec); // ask for it again on the next boot
        return finishError;
    }
    return finishOk;
}

ipmi::RspType<uint8_t> smcOob(uint8_t sub, uint8_t arg,
                              std::vector<uint8_t> rest)
{
    auto u32 = [&rest]() {
        return static_cast<uint32_t>(rest[0]) | (rest[1] << 8) |
               (rest[2] << 16) | (static_cast<uint32_t>(rest[3]) << 24);
    };

    switch (sub)
    {
        case subQuery:
        {
            auto type = typeOfQuery(arg);
            if (!type || !rest.empty())
            {
                return ipmi::responseInvalidCommand();
            }
            std::error_code ec;
            return ipmi::responseSuccess(fs::exists(storePath(*type), ec) ? 1
                                                                          : 0);
        }
        case subStart:
        {
            if (rest.size() != 4)
            {
                return ipmi::responseReqDataLenInvalid();
            }
            uint32_t size = u32();
            if (size == 0 || size > maxUpload)
            {
                return ipmi::responseParmOutOfRange();
            }
            uploads[arg].assign(size, 0);
            return ipmi::responseSuccess(0);
        }
        case subData:
        {
            auto it = uploads.find(arg);
            if (rest.size() <= 4)
            {
                return ipmi::responseReqDataLenInvalid();
            }
            uint32_t offset = u32();
            size_t len = rest.size() - 4;
            if (it == uploads.end() || offset >= it->second.size())
            {
                return ipmi::responseParmOutOfRange();
            }
            // The BIOS pads its last chunk: keep what fits.
            len = std::min(len, it->second.size() - offset);
            std::copy_n(rest.begin() + 4, len, it->second.begin() + offset);
            return ipmi::responseSuccess(0);
        }
        case subFinish:
        {
            if (!rest.empty())
            {
                return ipmi::responseReqDataLenInvalid();
            }
            return ipmi::responseSuccess(finish(arg));
        }
    }
    return ipmi::responseInvalidCommand();
}

// The stock handler reports "cannot access SEL device" because this image
// carries no SEL logger, and the BIOS then shows the BMC as not working.
ipmi::RspType<uint8_t, uint8_t> selfTest()
{
    return ipmi::responseSuccess(0x55, 0x00);
}

// The stock handler needs a D-Bus object this image does not have and
// answers with an unspecified error; the BIOS sends this on every boot.
ipmi::RspType<> setAcpiPowerState(uint8_t, uint8_t)
{
    return ipmi::responseSuccess();
}

} // namespace rd450x

void registerRd450xOem() __attribute__((constructor));
void registerRd450xOem()
{
    ipmi::registerHandler(ipmi::prioOemBase, ipmi::netFnOemOne,
                          rd450x::cmdSmcOob, ipmi::Privilege::Admin,
                          rd450x::smcOob);
    ipmi::registerHandler(ipmi::prioOemBase, ipmi::netFnApp,
                          ipmi::app::cmdGetSelfTestResults,
                          ipmi::Privilege::User, rd450x::selfTest);
    ipmi::registerHandler(ipmi::prioOemBase, ipmi::netFnApp,
                          ipmi::app::cmdSetAcpiPowerState,
                          ipmi::Privilege::Admin, rd450x::setAcpiPowerState);
}
