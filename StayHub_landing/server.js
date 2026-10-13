const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Phục vụ các file tĩnh (HTML, CSS, JS, Images)
app.use(express.static(path.join(__dirname, '/')));

// Endpoint nhận thông tin Lead từ Form
app.post('/api/leads', (req, res) => {
    const { name, phone, rooms } = req.body;
    
    // Ở đây ta có thể lưu vào Database, gửi email hoặc gửi qua Webhook (Telegram/Slack)
    console.log(`\n🎉 [NEW LEAD] Có khách hàng đăng ký tư vấn!`);
    console.log(`- Tên: ${name}`);
    console.log(`- Số ĐT: ${phone}`);
    console.log(`- Số lượng phòng: ${rooms}\n`);
    
    res.status(200).json({
        success: true,
        message: 'Đăng ký thành công! Đội ngũ StayHub sẽ liên hệ với bạn trong thời gian sớm nhất.'
    });
});

// Fallback route cho SPA hoặc trả về index.html
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
    console.log(`🚀 StayHub Landing Server is running at http://localhost:${PORT}`);
    console.log(`Waiting for leads...`);
});
