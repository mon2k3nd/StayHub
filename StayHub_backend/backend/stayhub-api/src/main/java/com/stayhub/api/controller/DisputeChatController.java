package com.stayhub.api.controller;

import com.stayhub.api.entity.DisputeMessage;
import com.stayhub.api.entity.Bill;
import com.stayhub.api.entity.NotificationType;
import com.stayhub.api.entity.NotificationScope;
import com.stayhub.api.repository.DisputeMessageRepository;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.List;

@RestController
@RequestMapping("/v1/disputes")
@RequiredArgsConstructor
public class DisputeChatController {

    private final DisputeMessageRepository disputeMessageRepository;
    private final BillRepository billRepository;
    private final RoomRepository roomRepository;
    private final NotificationService notificationService;
    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @GetMapping("/{billId}/messages")
    public List<DisputeMessage> getMessages(@PathVariable Long billId) {
        return disputeMessageRepository.findByBillIdOrderByCreatedAtAsc(billId);
    }

    @GetMapping(value = "/stream/{billId}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribe(@PathVariable Long billId) {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        emitters.computeIfAbsent(billId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        emitter.onCompletion(() -> removeEmitter(billId, emitter));
        emitter.onTimeout(() -> removeEmitter(billId, emitter));
        emitter.onError((e) -> removeEmitter(billId, emitter));

        try {
            emitter.send(SseEmitter.event().name("CONNECT").data("Connected to dispute " + billId));
        } catch (IOException e) {
            removeEmitter(billId, emitter);
        }

        return emitter;
    }

    private void removeEmitter(Long billId, SseEmitter emitter) {
        List<SseEmitter> list = emitters.get(billId);
        if (list != null) {
            list.remove(emitter);
        }
    }

    @PostMapping("/{billId}/messages")
    public Map<String, Object> sendMessage(@PathVariable Long billId, @RequestBody Map<String, String> payload) {
        String message = payload.get("message");
        String senderIdStr = payload.get("senderId");
        
        Long senderId = senderIdStr != null ? Long.parseLong(senderIdStr) : null;
        
        DisputeMessage msg = DisputeMessage.builder()
                .billId(billId)
                .senderId(senderId)
                .message(message)
                .createdAt(LocalDateTime.now())
                .build();
        disputeMessageRepository.save(msg);

        List<SseEmitter> list = emitters.get(billId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("MESSAGE").data(Map.of(
                            "senderId", senderIdStr != null ? senderIdStr : "",
                            "message", message
                    )));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(billId, emitter);
                }
            }
        }

        return Map.of("success", true);
    }
    
    @PostMapping("/{billId}/update-bill")
    public Map<String, Object> updateBill(@PathVariable Long billId, @RequestBody Map<String, Object> payload) {
        billRepository.findById(billId).ifPresent(bill -> {
            if (payload.containsKey("damageFee")) {
                bill.setDamageFee(Double.valueOf(payload.get("damageFee").toString()));
            }
            if (payload.containsKey("damageReason")) {
                bill.setDamageReason(payload.get("damageReason").toString());
            }
            if (payload.containsKey("totalAmount")) {
                bill.setTotalAmount(Double.valueOf(payload.get("totalAmount").toString()));
            }
            billRepository.save(bill);

            roomRepository.findById(bill.getRoomId()).ifPresent(room -> {
                notificationService.send(room.getOwnerId(), bill.getTenantId(), NotificationScope.INDIVIDUAL,
                        "Hóa đơn được cập nhật",
                        "Chủ nhà đã cập nhật lại hóa đơn phòng " + room.getRoomName() + " theo thỏa thuận.",
                        NotificationType.SYSTEM_ALERT, bill.getId(), false, null, "{\"event\":\"BILL_UPDATED\"}");
            });
        });

        List<SseEmitter> list = emitters.get(billId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("BILL_UPDATED").data(payload));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(billId, emitter);
                }
            }
        }
        return Map.of("success", true);
    }

    public void broadcastPaymentSuccess(Long billId) {
        List<SseEmitter> list = emitters.get(billId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("PAYMENT_SUCCESS").data(Map.of("success", true)));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(billId, emitter);
                }
            }
        }
    }

    public void broadcastContractSignedSuccess(Long roomId) {
        // Broadcast a global SSE event to the specific room's channel or similar
        // Since the current emitters are keyed by billId (which is basically an entity ID), 
        // we can reuse the same map keyed by roomId for simplicity in this prototype.
        List<SseEmitter> list = emitters.get(roomId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("OWNER_SIGNED_SUCCESS").data(Map.of("success", true)));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(roomId, emitter);
                }
            }
        }
    }

    public void broadcastTenantSignedSuccess(Long roomId) {
        List<SseEmitter> list = emitters.get(roomId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("TENANT_SIGNED_SUCCESS").data(Map.of("success", true)));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(roomId, emitter);
                }
            }
        }
    }
}
