package com.stayhub.api.dto.request;
import lombok.Data;
@Data
public class UpdateUtilitiesRequest {
    private Double electricCurrent;
    private Double waterCurrent;
    private String electricImage;
    private String waterImage;
}