package com.stayhub.api.service;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AddressData {
    public static final List<Map<String, Object>> PROVINCES_34 = Arrays.asList(
        createProvince("HNI", "Hà Nội", "Thành phố Hà Nội", "", Arrays.asList("01"), 1),
        createProvince("HUE", "Huế", "Thành phố Huế", "", Arrays.asList("46"), 46),
        createProvince("CBI", "Cao Bằng", "Tỉnh Cao Bằng", "", Arrays.asList("04"), 4),
        createProvince("DBI", "Điện Biên", "Tỉnh Điện Biên", "", Arrays.asList("11"), 11),
        createProvince("HTH", "Hà Tĩnh", "Tỉnh Hà Tĩnh", "", Arrays.asList("42"), 42),
        createProvince("LCU", "Lai Châu", "Tỉnh Lai Châu", "", Arrays.asList("12"), 12),
        createProvince("LSI", "Lạng Sơn", "Tỉnh Lạng Sơn", "", Arrays.asList("20"), 20),
        createProvince("NAN", "Nghệ An", "Tỉnh Nghệ An", "", Arrays.asList("40"), 40),
        createProvince("QNI", "Quảng Ninh", "Tỉnh Quảng Ninh", "", Arrays.asList("22"), 22),
        createProvince("SNI", "Sơn La", "Tỉnh Sơn La", "", Arrays.asList("14"), 14),
        createProvince("THA", "Thanh Hóa", "Tỉnh Thanh Hóa", "", Arrays.asList("38"), 38),
        createProvince("TQI", "Tuyên Quang", "Tỉnh Tuyên Quang", "Hà Giang, Tuyên Quang", Arrays.asList("02", "08"), 8),
        createProvince("LCI", "Lào Cai", "Tỉnh Lào Cai", "Yên Bái, Lào Cai", Arrays.asList("15", "10"), 15),
        createProvince("TNI", "Thái Nguyên", "Tỉnh Thái Nguyên", "Bắc Kạn, Thái Nguyên", Arrays.asList("06", "19"), 19),
        createProvince("PTH", "Phú Thọ", "Tỉnh Phú Thọ", "Vĩnh Phúc, Hòa Bình, Phú Thọ", Arrays.asList("26", "17", "25"), 25),
        createProvince("BNI", "Bắc Ninh", "Tỉnh Bắc Ninh", "Bắc Giang, Bắc Ninh", Arrays.asList("24", "27"), 24),
        createProvince("HYN", "Hưng Yên", "Tỉnh Hưng Yên", "Thái Bình, Hưng Yên", Arrays.asList("34", "33"), 33),
        createProvince("HPI", "Hải Phòng", "Thành phố Hải Phòng", "Hải Dương, Hải Phòng", Arrays.asList("30", "31"), 31),
        createProvince("NBH", "Ninh Bình", "Tỉnh Ninh Bình", "Hà Nam, Nam Định, Ninh Bình", Arrays.asList("35", "36", "37"), 37),
        createProvince("QTR", "Quảng Trị", "Tỉnh Quảng Trị", "Quảng Bình, Quảng Trị", Arrays.asList("44", "45"), 44),
        createProvince("DAN", "Đà Nẵng", "Thành phố Đà Nẵng", "Quảng Nam, Đà Nẵng", Arrays.asList("49", "48"), 48),
        createProvince("QNG", "Quảng Ngãi", "Tỉnh Quảng Ngãi", "Kon Tum, Quảng Ngãi", Arrays.asList("62", "51"), 51),
        createProvince("GLA", "Gia Lai", "Tỉnh Gia Lai", "Bình Định, Gia Lai", Arrays.asList("52", "64"), 52),
        createProvince("KHA", "Khánh Hòa", "Tỉnh Khánh Hòa", "Ninh Thuận, Khánh Hòa", Arrays.asList("58", "56"), 56),
        createProvince("LDG", "Lâm Đồng", "Tỉnh Lâm Đồng", "Đắk Nông, Bình Thuận, Lâm Đồng", Arrays.asList("67", "60", "68"), 68),
        createProvince("DAK", "Đắk Lắk", "Tỉnh Đắk Lắk", "Phú Yên, Đắk Lắk", Arrays.asList("54", "66"), 66),
        createProvince("HCM", "Hồ Chí Minh", "Thành phố Hồ Chí Minh", "Hồ Chí Minh, Bình Dương, Bà Rịa - Vũng Tàu", Arrays.asList("79", "74", "77"), 79),
        createProvince("DNI", "Đồng Nai", "Tỉnh Đồng Nai", "Đồng Nai, Bình Phước", Arrays.asList("75", "70"), 75),
        createProvince("TNH", "Tây Ninh", "Tỉnh Tây Ninh", "Tây Ninh, Long An", Arrays.asList("72", "80"), 80),
        createProvince("CTH", "Cần Thơ", "Thành phố Cần Thơ", "Cần Thơ, Sóc Trăng, Hậu Giang", Arrays.asList("92", "94", "93"), 92),
        createProvince("VLG", "Vĩnh Long", "Tỉnh Vĩnh Long", "Bến Tre, Vĩnh Long, Trà Vinh", Arrays.asList("83", "86", "84"), 86),
        createProvince("DTP", "Đồng Tháp", "Tỉnh Đồng Tháp", "Tiền Giang, Đồng Tháp", Arrays.asList("82", "87"), 82),
        createProvince("CMU", "Cà Mau", "Tỉnh Cà Mau", "Bạc Liêu, Cà Mau", Arrays.asList("95", "96"), 96),
        createProvince("AGI", "An Giang", "Tỉnh An Giang", "Kiên Giang, An Giang", Arrays.asList("91", "89"), 91)
    );

    public static final Map<String, String> ESGOO_ID_TO_NEW_34 = new HashMap<>();

    static {
        ESGOO_ID_TO_NEW_34.put("01", "HNI");
        ESGOO_ID_TO_NEW_34.put("46", "HUE");
        ESGOO_ID_TO_NEW_34.put("04", "CBI");
        ESGOO_ID_TO_NEW_34.put("11", "DBI");
        ESGOO_ID_TO_NEW_34.put("42", "HTH");
        ESGOO_ID_TO_NEW_34.put("12", "LCU");
        ESGOO_ID_TO_NEW_34.put("20", "LSI");
        ESGOO_ID_TO_NEW_34.put("40", "NAN");
        ESGOO_ID_TO_NEW_34.put("22", "QNI");
        ESGOO_ID_TO_NEW_34.put("14", "SNI");
        ESGOO_ID_TO_NEW_34.put("38", "THA");
        ESGOO_ID_TO_NEW_34.put("02", "TQI");
        ESGOO_ID_TO_NEW_34.put("08", "TQI");
        ESGOO_ID_TO_NEW_34.put("15", "LCI");
        ESGOO_ID_TO_NEW_34.put("10", "LCI");
        ESGOO_ID_TO_NEW_34.put("06", "TNI");
        ESGOO_ID_TO_NEW_34.put("19", "TNI");
        ESGOO_ID_TO_NEW_34.put("26", "PTH");
        ESGOO_ID_TO_NEW_34.put("25", "PTH");
        ESGOO_ID_TO_NEW_34.put("17", "PTH");
        ESGOO_ID_TO_NEW_34.put("24", "BNI");
        ESGOO_ID_TO_NEW_34.put("27", "BNI");
        ESGOO_ID_TO_NEW_34.put("34", "HYN");
        ESGOO_ID_TO_NEW_34.put("33", "HYN");
        ESGOO_ID_TO_NEW_34.put("30", "HPI");
        ESGOO_ID_TO_NEW_34.put("31", "HPI");
        ESGOO_ID_TO_NEW_34.put("35", "NBH");
        ESGOO_ID_TO_NEW_34.put("36", "NBH");
        ESGOO_ID_TO_NEW_34.put("37", "NBH");
        ESGOO_ID_TO_NEW_34.put("44", "QTR");
        ESGOO_ID_TO_NEW_34.put("45", "QTR");
        ESGOO_ID_TO_NEW_34.put("49", "DAN");
        ESGOO_ID_TO_NEW_34.put("48", "DAN");
        ESGOO_ID_TO_NEW_34.put("62", "QNG");
        ESGOO_ID_TO_NEW_34.put("51", "QNG");
        ESGOO_ID_TO_NEW_34.put("52", "GLA");
        ESGOO_ID_TO_NEW_34.put("64", "GLA");
        ESGOO_ID_TO_NEW_34.put("58", "KHA");
        ESGOO_ID_TO_NEW_34.put("56", "KHA");
        ESGOO_ID_TO_NEW_34.put("67", "LDG");
        ESGOO_ID_TO_NEW_34.put("60", "LDG");
        ESGOO_ID_TO_NEW_34.put("68", "LDG");
        ESGOO_ID_TO_NEW_34.put("54", "DAK");
        ESGOO_ID_TO_NEW_34.put("66", "DAK");
        ESGOO_ID_TO_NEW_34.put("79", "HCM");
        ESGOO_ID_TO_NEW_34.put("74", "HCM");
        ESGOO_ID_TO_NEW_34.put("77", "HCM");
        ESGOO_ID_TO_NEW_34.put("75", "DNI");
        ESGOO_ID_TO_NEW_34.put("70", "DNI");
        ESGOO_ID_TO_NEW_34.put("72", "TNH");
        ESGOO_ID_TO_NEW_34.put("80", "TNH");
        ESGOO_ID_TO_NEW_34.put("92", "CTH");
        ESGOO_ID_TO_NEW_34.put("94", "CTH");
        ESGOO_ID_TO_NEW_34.put("93", "CTH");
        ESGOO_ID_TO_NEW_34.put("83", "VLG");
        ESGOO_ID_TO_NEW_34.put("86", "VLG");
        ESGOO_ID_TO_NEW_34.put("84", "VLG");
        ESGOO_ID_TO_NEW_34.put("82", "DTP");
        ESGOO_ID_TO_NEW_34.put("87", "DTP");
        ESGOO_ID_TO_NEW_34.put("95", "CMU");
        ESGOO_ID_TO_NEW_34.put("96", "CMU");
        ESGOO_ID_TO_NEW_34.put("91", "AGI");
        ESGOO_ID_TO_NEW_34.put("89", "AGI");
    }

    private static Map<String, Object> createProvince(String id, String name, String display, String subtitle, List<String> esgooIds, int openApiCode) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", id);
        map.put("name", name);
        map.put("display", display);
        map.put("subtitle", subtitle);
        map.put("esgoo_ids", esgooIds);
        map.put("open_api_code", openApiCode);
        return map;
    }

    public static Map<String, Object> getNew34ByEsgooId(String esgooId) {
        String newId = ESGOO_ID_TO_NEW_34.get(esgooId);
        if (newId == null) return null;
        for (Map<String, Object> p : PROVINCES_34) {
            if (newId.equals(p.get("id"))) {
                return p;
            }
        }
        return null;
    }
}
