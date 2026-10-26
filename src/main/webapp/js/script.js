/**
 * MEETING ROOM BOOKING SYSTEM - CLIENT SCRIPTS
 */

// Initialize Theme on Load
document.addEventListener('DOMContentLoaded', function () {
    const savedTheme = localStorage.getItem('meetroom_theme') || 'light';
    applyTheme(savedTheme);

    // 1. Auto-dismiss alerts after 6 seconds
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(function (alert) {
        setTimeout(function () {
            const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
            if (bsAlert) bsAlert.close();
        }, 6000);
    });

    // 2. Set min date for date inputs to today
    const dateInputs = document.querySelectorAll('input[type="date"]');
    const today = new Date().toISOString().split('T')[0];
    dateInputs.forEach(function (input) {
        if (!input.getAttribute('min')) {
            input.setAttribute('min', today);
        }
    });

    // 3. Booking form time validation & price calculator hooks
    const bookingForm = document.getElementById('bookingForm');
    if (bookingForm) {
        bookingForm.addEventListener('submit', function (e) {
            const startTime = document.getElementById('startTime').value;
            const endTime = document.getElementById('endTime').value;

            if (startTime && endTime && startTime >= endTime) {
                e.preventDefault();
                alert('Validation Error: Meeting Start Time must be strictly before End Time.');
                return false;
            }

            const roomSelect = document.getElementById('roomId');
            const participantsInput = document.getElementById('participants');
            if (roomSelect && participantsInput) {
                const selectedOption = roomSelect.options[roomSelect.selectedIndex];
                const capacity = parseInt(selectedOption.getAttribute('data-capacity') || '9999', 10);
                const participants = parseInt(participantsInput.value || '1', 10);

                if (participants > capacity) {
                    if (!confirm(`Warning: The requested participant count (${participants}) exceeds the room's listed capacity (${capacity}). Proceed anyway?`)) {
                        e.preventDefault();
                        return false;
                    }
                }
            }
        });

        // Price calculator event listeners
        const roomIdEl = document.getElementById('roomId');
        const startEl = document.getElementById('startTime');
        const endEl = document.getElementById('endTime');
        const userTypeEl = document.getElementById('userType');

        if (roomIdEl) roomIdEl.addEventListener('change', calculateBookingPrice);
        if (startEl) startEl.addEventListener('change', calculateBookingPrice);
        if (endEl) endEl.addEventListener('change', calculateBookingPrice);
        if (userTypeEl) userTypeEl.addEventListener('change', calculateBookingPrice);

        // Initial calculation
        calculateBookingPrice();
    }

    // 4. Update room details preview when room select changes
    const roomSelect = document.getElementById('roomId');
    if (roomSelect) {
        roomSelect.addEventListener('change', function () {
            updateRoomCapacityNotice(this);
        });
        updateRoomCapacityNotice(roomSelect);
    }
});

/**
 * Mobile Sidebar Drawer Toggle
 */
function toggleSidebar() {
    const sidebar = document.getElementById('appSidebar');
    const overlay = document.getElementById('sidebarOverlay');
    if (sidebar) sidebar.classList.toggle('show');
    if (overlay) overlay.classList.toggle('show');
}

/**
 * Theme Switcher Logic (Light & Dark Theme)
 */
function toggleTheme() {
    const current = document.documentElement.getAttribute('data-bs-theme') === 'dark' ? 'dark' : 'light';
    const next = current === 'dark' ? 'light' : 'dark';
    applyTheme(next);
}

function applyTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);
    localStorage.setItem('meetroom_theme', theme);

    // Update buttons UI
    const isDark = (theme === 'dark');
    document.querySelectorAll('.theme-icon-light').forEach(el => el.classList.toggle('d-none', !isDark));
    document.querySelectorAll('.theme-icon-dark').forEach(el => el.classList.toggle('d-none', isDark));
    document.querySelectorAll('.theme-text-light').forEach(el => el.classList.toggle('d-none', !isDark));
    document.querySelectorAll('.theme-text-dark').forEach(el => el.classList.toggle('d-none', isDark));
}

/**
 * Dynamic Live Pricing & Discount Calculator
 */
function calculateBookingPrice() {
    const roomSelect = document.getElementById('roomId');
    const startInput = document.getElementById('startTime');
    const endInput = document.getElementById('endTime');
    const userTypeSelect = document.getElementById('userType');

    if (!roomSelect || !startInput || !endInput) return;

    let hourlyRate = 15.00;
    const selectedOption = roomSelect.options[roomSelect.selectedIndex];
    if (selectedOption && selectedOption.getAttribute('data-rate')) {
        hourlyRate = parseFloat(selectedOption.getAttribute('data-rate')) || 15.00;
    }

    const startVal = startInput.value;
    const endVal = endInput.value;

    let hours = 1.0;
    if (startVal && endVal && startVal < endVal) {
        const [sh, sm] = startVal.split(':').map(Number);
        const [eh, em] = endVal.split(':').map(Number);
        const startMinutes = sh * 60 + sm;
        const endMinutes = eh * 60 + em;
        const diffMinutes = Math.max(30, endMinutes - startMinutes);
        hours = Math.round((diffMinutes / 60.0) * 10) / 10;
        if (hours <= 0) hours = 1.0;
    }

    const userType = userTypeSelect ? userTypeSelect.value : 'Student';
    const isStudent = (userType === 'Student' || userType === 'Student Club');

    const subtotal = hours * hourlyRate;
    const discount = isStudent ? (subtotal * 0.20) : 0.00;
    const total = Math.max(0, subtotal - discount);

    // Update Live UI
    const calcHoursEl = document.getElementById('calcHours');
    const calcRateEl = document.getElementById('calcRate');
    const calcSubtotalEl = document.getElementById('calcSubtotal');
    const calcDiscountRow = document.getElementById('calcDiscountRow');
    const calcDiscountEl = document.getElementById('calcDiscount');
    const calcTotalEl = document.getElementById('calcTotalAmount');

    if (calcHoursEl) calcHoursEl.textContent = hours.toFixed(1) + ' hrs';
    if (calcRateEl) calcRateEl.textContent = '$' + hourlyRate.toFixed(2) + ' / hr';
    if (calcSubtotalEl) calcSubtotalEl.textContent = '$' + subtotal.toFixed(2);

    if (calcDiscountRow && calcDiscountEl) {
        if (isStudent) {
            calcDiscountRow.classList.remove('d-none');
            calcDiscountEl.textContent = '-$' + discount.toFixed(2) + ' (20% Student Subsidy)';
        } else {
            calcDiscountRow.classList.add('d-none');
        }
    }

    if (calcTotalEl) calcTotalEl.textContent = '$' + total.toFixed(2);

    // Live update dynamic QR Code and payment badge
    const qrBadge = document.getElementById('qrPayAmountBadge');
    const qrImg = document.getElementById('liveQrCodeImg');
    if (qrBadge) qrBadge.textContent = 'Amount to Pay: $' + total.toFixed(2);
    if (qrImg) {
        const upiData = 'upi://pay?pa=meetroom@axisbank&pn=MeetRoom%20Pro&am=' + total.toFixed(2) + '&cu=INR';
        qrImg.src = 'https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=' + encodeURIComponent(upiData);
    }
}

/**
 * Payment Method Selection (Online vs Offline)
 */
function selectPaymentMethod(method) {
    const input = document.getElementById('paymentMethodInput');
    if (input) input.value = method;

    const onlineCard = document.getElementById('paymentCardOnline');
    const offlineCard = document.getElementById('paymentCardOffline');
    const onlineDrawer = document.getElementById('onlinePaymentDetails');
    const offlineDrawer = document.getElementById('offlinePaymentDetails');

    if (method.toLowerCase().includes('online')) {
        if (onlineCard) onlineCard.classList.add('selected');
        if (offlineCard) offlineCard.classList.remove('selected');
        if (onlineDrawer) onlineDrawer.classList.remove('d-none');
        if (offlineDrawer) offlineDrawer.classList.add('d-none');
    } else {
        if (offlineCard) offlineCard.classList.add('selected');
        if (onlineCard) onlineCard.classList.remove('selected');
        if (onlineDrawer) onlineDrawer.classList.add('d-none');
        if (offlineDrawer) offlineDrawer.classList.remove('d-none');
    }
}

/**
 * Update room capacity notice
 */
function updateRoomCapacityNotice(selectElement) {
    const noticeEl = document.getElementById('roomCapacityNotice');
    if (!noticeEl) return;
    const selectedOption = selectElement.options[selectElement.selectedIndex];
    if (selectedOption && selectedOption.value) {
        const capacity = selectedOption.getAttribute('data-capacity') || 'N/A';
        const type = selectedOption.getAttribute('data-type') || 'Meeting Room';
        const rate = selectedOption.getAttribute('data-rate') || '15.00';
        noticeEl.innerHTML = `<i class="bi bi-info-circle me-1"></i> Room Type: <strong>${type}</strong> &bull; Capacity: <strong>${capacity} seats</strong> &bull; Hourly Rate: <strong>$${parseFloat(rate).toFixed(2)}/hr</strong>`;
        noticeEl.classList.remove('d-none');
    } else {
        noticeEl.classList.add('d-none');
    }
}

/**
 * Pre-populate Room Edit Modal
 */
function openEditRoomModal(id, number, name, building, floor, capacity, type, facilities, hourlyRate, status) {
    document.getElementById('editRoomId').value = id;
    document.getElementById('editRoomNumber').value = number;
    document.getElementById('editRoomName').value = name;
    document.getElementById('editBuilding').value = building;
    document.getElementById('editFloor').value = floor;
    document.getElementById('editCapacity').value = capacity;
    document.getElementById('editRoomType').value = type;
    document.getElementById('editFacilities').value = facilities;
    if (document.getElementById('editHourlyRate')) {
        document.getElementById('editHourlyRate').value = hourlyRate || 15.00;
    }
    document.getElementById('editStatus').value = status;

    const modal = new bootstrap.Modal(document.getElementById('editRoomModal'));
    modal.show();
}

/**
 * Confirm delete room
 */
function confirmDeleteRoom(roomName) {
    return confirm(`Are you sure you want to delete room "${roomName}"? This action cannot be undone.`);
}

/**
 * Confirm cancel booking
 */
function confirmCancelBooking(bookingNum) {
    return confirm(`Are you sure you want to cancel booking "${bookingNum}"?`);
}

/**
 * Confirm delete booking
 */
function confirmDeleteBooking(bookingNum) {
    return confirm(`Are you sure you want to permanently delete booking "${bookingNum}"?`);
}
