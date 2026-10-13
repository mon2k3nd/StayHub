document.addEventListener('DOMContentLoaded', () => {

    // ===== PARTICLE BACKGROUND =====
    const canvas = document.getElementById('particle-canvas');
    const ctx = canvas.getContext('2d');
    let particles = [];

    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }

    function createParticles() {
        particles = [];
        const count = Math.floor((window.innerWidth * window.innerHeight) / 18000);
        for (let i = 0; i < count; i++) {
            particles.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height,
                r: Math.random() * 1.5 + 0.3,
                vx: (Math.random() - 0.5) * 0.3,
                vy: (Math.random() - 0.5) * 0.3,
                alpha: Math.random() * 0.5 + 0.1,
            });
        }
    }

    function drawParticles() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        particles.forEach(p => {
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(79, 142, 247, ${p.alpha})`;
            ctx.fill();
            p.x += p.vx;
            p.y += p.vy;
            if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
            if (p.y < 0 || p.y > canvas.height) p.vy *= -1;
        });
        requestAnimationFrame(drawParticles);
    }

    resizeCanvas();
    createParticles();
    drawParticles();
    window.addEventListener('resize', () => { resizeCanvas(); createParticles(); });


    // ===== NAVBAR SCROLL =====
    const nav = document.getElementById('main-nav');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 60) {
            nav.classList.add('scrolled');
        } else {
            nav.classList.remove('scrolled');
        }
    });


    // ===== HAMBURGER MOBILE MENU =====
    const hamburger = document.getElementById('hamburger');
    const mobileMenu = document.getElementById('mobile-menu');
    hamburger.addEventListener('click', () => {
        mobileMenu.classList.toggle('open');
    });
    mobileMenu.querySelectorAll('a').forEach(a => {
        a.addEventListener('click', () => mobileMenu.classList.remove('open'));
    });


    // ===== SMOOTH SCROLLING =====
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href === '#') return;
            e.preventDefault();
            const target = document.querySelector(href);
            if (target) {
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });


    // ===== SCROLL REVEAL =====
    const revealEls = document.querySelectorAll('.reveal, .reveal-left, .reveal-right');
    const revealObs = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
                revealObs.unobserve(entry.target);
            }
        });
    }, { threshold: 0.12, rootMargin: '0px 0px -60px 0px' });
    revealEls.forEach(el => revealObs.observe(el));


    // ===== COUNTER ANIMATION =====
    function animateCounter(el) {
        const target = parseInt(el.getAttribute('data-target'));
        const duration = 2000;
        const step = (target / duration) * 16;
        let current = 0;
        const timer = setInterval(() => {
            current += step;
            if (current >= target) {
                current = target;
                clearInterval(timer);
            }
            el.textContent = Math.floor(current).toLocaleString('vi-VN');
        }, 16);
    }

    const counterEls = document.querySelectorAll('.trust-number[data-target]');
    const counterObs = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                counterObs.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    counterEls.forEach(el => counterObs.observe(el));


    // ===== PRICING TOGGLE =====
    const billingSwitch = document.getElementById('billing-switch');
    const labelMonthly = document.getElementById('label-monthly');
    const labelYearly = document.getElementById('label-yearly');
    const priceValues = document.querySelectorAll('.price-value');

    function animatePrice(el, from, to) {
        const duration = 300;
        const start = performance.now();
        const update = (now) => {
            const t = Math.min((now - start) / duration, 1);
            const ease = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
            el.textContent = Math.round(from + (to - from) * ease);
            if (t < 1) requestAnimationFrame(update);
        };
        requestAnimationFrame(update);
    }

    if (billingSwitch) {
        billingSwitch.addEventListener('change', () => {
            const isYearly = billingSwitch.checked;
            labelYearly.classList.toggle('active', isYearly);
            labelMonthly.classList.toggle('active', !isYearly);

            priceValues.forEach(el => {
                const from = parseInt(el.textContent);
                const to = parseInt(el.getAttribute(isYearly ? 'data-yearly' : 'data-monthly'));
                animatePrice(el, from, to);
            });
        });

        // Initial active label
        labelMonthly.classList.add('active');
    }


    // ===== DASHBOARD CHART ANIMATION =====
    const bars = document.querySelectorAll('.dc-chart-bar, .mini-bar');
    bars.forEach((bar, i) => {
        const h = bar.style.height;
        bar.style.height = '0%';
        setTimeout(() => {
            bar.style.transition = `height 0.6s cubic-bezier(0.16, 1, 0.3, 1) ${i * 60}ms`;
            bar.style.height = h;
        }, 800);
    });


    // ===== HERO MOUSE PARALLAX =====
    const heroVisual = document.querySelector('.hero-visual');
    if (heroVisual) {
        document.addEventListener('mousemove', (e) => {
            const xRatio = (e.clientX / window.innerWidth - 0.5) * 2;
            const yRatio = (e.clientY / window.innerHeight - 0.5) * 2;
            heroVisual.style.transform = `translate(${xRatio * -8}px, ${yRatio * -5}px)`;
        });
    }

    // ===== ACTIVE NAV LINK ON SCROLL =====
    const sections = document.querySelectorAll('section[id], header[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    const sectionObs = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const id = entry.target.getAttribute('id');
                navLinks.forEach(link => {
                    link.classList.remove('active-nav');
                    if (link.getAttribute('href') === `#${id}`) {
                        link.classList.add('active-nav');
                    }
                });
            }
        });
    }, { threshold: 0.4 });
    sections.forEach(s => sectionObs.observe(s));

    // ===== ROI CALCULATOR (PHASE 7.1) =====
    const roomSlider = document.getElementById('roomSlider');
    const roomCountLabel = document.getElementById('roomCountLabel');
    const timeSavedEl = document.getElementById('timeSaved');
    const moneySavedEl = document.getElementById('moneySaved');
    const suggestedPlanEl = document.getElementById('suggestedPlan');

    if (roomSlider) {
        roomSlider.addEventListener('input', (e) => {
            const val = parseInt(e.target.value);
            roomCountLabel.textContent = `${val} phòng`;
            
            // Logic tính toán:
            // Tiết kiệm: 0.5 giờ / phòng
            const timeSaved = Math.round(val * 0.5);
            // Tiết kiệm tiền rò rỉ: giả sử 100k/phòng/tháng
            const moneySaved = val * 100000;
            
            // Update UI with animation
            animatePrice(timeSavedEl, parseInt(timeSavedEl.textContent.replace(/,/g, '')), timeSaved);
            animatePrice(moneySavedEl, parseInt(moneySavedEl.textContent.replace(/,/g, '')), moneySaved);

            // Gợi ý gói
            if (val <= 10) suggestedPlanEl.textContent = 'Gói BASIC';
            else if (val <= 50) suggestedPlanEl.textContent = 'Gói PRO';
            else suggestedPlanEl.textContent = 'Gói ENTERPRISE';
        });
    }

    // ===== LEAD FORM SUBMISSION (PHASE 7.1) =====
    const newLeadForm = document.getElementById('leadForm');
    if (newLeadForm) {
        newLeadForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('leadSubmitBtn');
            const msgEl = document.getElementById('leadFormMsg');
            
            const formData = {
                name: document.getElementById('leadName').value,
                phone: document.getElementById('leadPhone').value,
                rooms: document.getElementById('leadRooms').value
            };

            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Đang Gửi...';
            msgEl.className = 'form-msg';

            try {
                const res = await fetch('/api/leads', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData)
                });
                
                const data = await res.json();
                msgEl.textContent = data.message || 'Tuyệt vời! StayHub sẽ liên hệ với bạn sớm nhất.';
                msgEl.classList.add('success');
                newLeadForm.reset();
            } catch (err) {
                msgEl.textContent = 'Có lỗi xảy ra, vui lòng thử lại sau.';
                msgEl.classList.add('error');
            } finally {
                btn.disabled = false;
                btn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Đăng Ký Tư Vấn Miễn Phí';
            }
        });
    }
});
