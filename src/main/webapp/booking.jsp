<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.meetingroom.Room, com.meetingroom.Booking" %>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Room> rooms = (List<Room>) request.getAttribute("rooms");
    if (rooms == null) {
        String q = request.getQueryString();
        response.sendRedirect(request.getContextPath() + "/bookings" + (q != null ? "?" + q : ""));
        return;
    }

    Booking editBooking = (Booking) request.getAttribute("editBooking");
    boolean isEdit = (editBooking != null);

    String error = request.getParameter("error");
    String success = request.getParameter("success");

    // Pre-fill parameters (from Room Availability or default)
    String preRoomId = request.getParameter("roomId");
    String preDate = request.getParameter("date");
    String preStart = request.getParameter("startTime");
    String preEnd = request.getParameter("endTime");
    String preParticipants = request.getParameter("participants");
    String preUserType = "Student";

    if (isEdit) {
        preRoomId = String.valueOf(editBooking.getRoomId());
        preDate = editBooking.getMeetingDate();
        preStart = editBooking.getStartTime().substring(0, 5);
        preEnd = editBooking.getEndTime().substring(0, 5);
        preParticipants = String.valueOf(editBooking.getParticipants());
        preUserType = editBooking.getUserType();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isEdit ? "Edit Reservation" : "Book a Meeting Room" %> - MeetRoom Pro</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS (with cache buster) -->
    <link href="<%= request.getContextPath() %>/css/style.css?v=3.1" rel="stylesheet">
</head>
<body>

    <!-- Main Left Sidebar & Mobile Navigation -->
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="container-fluid py-2">

            <!-- Meeting Room Photo Hero Header -->
            <div class="card card-custom border-0 overflow-hidden mb-4 shadow-sm position-relative text-white" style="min-height: 140px; border-radius: 14px;">
                <img src="<%= request.getContextPath() %>/images/meeting-room-hero.jpg" alt="Meeting Room" class="position-absolute top-0 start-0 w-100 h-100" style="object-fit: cover; filter: brightness(0.35);">
                <div class="card-body position-relative p-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <span class="badge bg-warning text-dark mb-1"><i class="bi bi-mortarboard-fill me-1"></i> Student 20% Subsidy Auto-Applied</span>
                        <h3 class="fw-bold mb-0 text-white"><%= isEdit ? "Edit Meeting Room Reservation" : "Reserve Your Meeting Space" %></h3>
                        <small class="text-white-50">Zero conflict double-booking protection &bull; Instant Online UPI / Card &bull; Pay at Desk</small>
                    </div>
                    <a href="<%= request.getContextPath() %>/history" class="btn btn-light btn-sm fw-semibold shadow">
                        <i class="bi bi-arrow-left me-1"></i> View All Bookings
                    </a>
                </div>
            </div>

            <div class="row justify-content-center">
                <div class="col-xl-11 col-xxl-10">

                    <!-- Header -->
                    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                        <div>
                            <h2 class="fw-bold mb-1">
                                <i class="bi <%= isEdit ? "bi-pencil-square text-warning" : "bi-calendar-plus text-primary" %> me-2"></i>
                                <%= isEdit ? "Edit Reservation #" + editBooking.getBookingNumber() : "Reserve a Meeting Room" %>
                            </h2>
                            <p class="text-muted mb-0">Select room, schedule time, review automatic student discounts, and choose payment mode.</p>
                        </div>
                        <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-secondary">
                            <i class="bi bi-arrow-left me-1"></i> View All Bookings
                        </a>
                    </div>

                    <!-- Validation / Error Alert -->
                    <% if (error != null && !error.isEmpty()) { %>
                        <div class="alert alert-danger alert-dismissible fade show border-danger shadow-sm mb-4" role="alert">
                            <div class="d-flex">
                                <i class="bi bi-exclamation-octagon-fill fs-4 me-3 text-danger"></i>
                                <div>
                                    <h6 class="alert-heading fw-bold mb-1">Booking Conflict or Error</h6>
                                    <div><%= error %></div>
                                </div>
                            </div>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    <% } %>

                    <!-- Main Booking Form Card -->
                    <div class="card card-custom border-0 shadow-sm">
                        <div class="card-header-custom d-flex justify-content-between align-items-center">
                            <span class="fw-bold"><i class="bi bi-file-earmark-text me-2 text-primary"></i>Reservation &amp; Billing Specifications</span>
                            <span class="badge bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25 px-3 py-1">
                                <i class="bi bi-shield-check me-1"></i> Smart Conflict Prevention Active
                            </span>
                        </div>
                        <div class="card-body p-4">
                            <form action="<%= request.getContextPath() %>/bookings" method="post" id="bookingForm">
                                <input type="hidden" name="action" value="<%= isEdit ? "update" : "book" %>">
                                <% if (isEdit) { %>
                                    <input type="hidden" name="bookingId" value="<%= editBooking.getBookingId() %>">
                                <% } %>

                                <!-- Section 1: User Profile & Role (Discount Determination) -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-person-badge me-1"></i> 1. User Category &amp; Campus Privilege
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-4">
                                        <label for="userType" class="form-label fw-semibold">User Role / Category *</label>
                                        <select name="userType" id="userType" class="form-select form-select-lg" required>
                                            <option value="Student" <%= "Student".equalsIgnoreCase(preUserType) ? "selected" : "" %>>🎓 College Student (20% Subsidy)</option>
                                            <option value="Student Club" <%= "Student Club".equalsIgnoreCase(preUserType) ? "selected" : "" %>>🏛️ Student Club / Tech Society (20% Subsidy)</option>
                                            <option value="Faculty" <%= "Faculty".equalsIgnoreCase(preUserType) ? "selected" : "" %>>👨‍🏫 Faculty / Academic Staff</option>
                                            <option value="Employee" <%= "Employee".equalsIgnoreCase(preUserType) ? "selected" : "" %>>💼 Corporate / Employee</option>
                                        </select>
                                        <small class="text-success"><i class="bi bi-check-circle-fill me-1"></i> Students receive an instant 20% discount.</small>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="employeeName" class="form-label fw-semibold">Full Name *</label>
                                        <input type="text" name="employeeName" id="employeeName" class="form-control form-control-lg" placeholder="e.g. Alex Johnson" value="<%= isEdit ? editBooking.getEmployeeName() : "" %>" required>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="employeeId" class="form-label fw-semibold">ID / Roll Number *</label>
                                        <input type="text" name="employeeId" id="employeeId" class="form-control form-control-lg" placeholder="e.g. STU-2024-889 or EMP-104" value="<%= isEdit ? editBooking.getEmployeeId() : "" %>" required>
                                    </div>
                                    <div class="col-md-6">
                                        <label for="department" class="form-label fw-semibold">Department / Society / Org</label>
                                        <input type="text" name="department" id="department" class="form-control" placeholder="e.g. Computer Science / Robotics Club / Marketing" value="<%= isEdit && editBooking.getDepartment() != null ? editBooking.getDepartment() : "" %>">
                                    </div>
                                    <div class="col-md-6">
                                        <label for="meetingTitle" class="form-label fw-semibold">Meeting / Event Title *</label>
                                        <input type="text" name="meetingTitle" id="meetingTitle" class="form-control" placeholder="e.g. AI Hackathon Briefing / Project Defense" value="<%= isEdit ? editBooking.getMeetingTitle() : "" %>" required>
                                    </div>
                                </div>

                                <!-- Section 2: Room Selection & Attendees -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-door-open me-1"></i> 2. Room Selection &amp; Capacity
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-8">
                                        <label for="roomId" class="form-label fw-semibold">Select Meeting Room *</label>
                                        <select name="roomId" id="roomId" class="form-select form-select-lg" required>
                                            <option value="">-- Choose a meeting or conference room --</option>
                                            <% for (Room r : rooms) { %>
                                                <option value="<%= r.getRoomId() %>"
                                                        data-capacity="<%= r.getCapacity() %>"
                                                        data-type="<%= r.getRoomType() %>"
                                                        data-rate="<%= r.getHourlyRate() %>"
                                                        <%= (preRoomId != null && preRoomId.equals(String.valueOf(r.getRoomId()))) ? "selected" : "" %>>
                                                    <%= r.getRoomNumber() %> - <%= r.getRoomName() %> &bull; <%= r.getBuilding() %> &bull; Cap: <%= r.getCapacity() %> &bull; $<%= String.format("%.2f", r.getHourlyRate()) %>/hr
                                                </option>
                                            <% } %>
                                        </select>
                                        <div id="roomCapacityNotice" class="alert alert-info py-2 px-3 mt-2 small d-none"></div>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="participants" class="form-label fw-semibold">Expected Attendees *</label>
                                        <div class="input-group input-group-lg">
                                            <span class="input-group-text"><i class="bi bi-people"></i></span>
                                            <input type="number" name="participants" id="participants" class="form-control" min="1" max="500" value="<%= preParticipants != null ? preParticipants : "6" %>" required>
                                        </div>
                                        <small class="text-muted">Must be &le; selected room capacity.</small>
                                    </div>
                                </div>

                                <!-- Section 3: Date & Time Schedule -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-clock me-1"></i> 3. Date &amp; Time Slot
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-4">
                                        <label for="meetingDate" class="form-label fw-semibold">Meeting Date *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="bi bi-calendar3"></i></span>
                                            <input type="date" name="meetingDate" id="meetingDate" class="form-control" value="<%= preDate != null ? preDate : "" %>" required>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="startTime" class="form-label fw-semibold">Start Time *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="bi bi-clock"></i></span>
                                            <input type="time" name="startTime" id="startTime" class="form-control" value="<%= preStart != null ? preStart : "10:00" %>" required>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="endTime" class="form-label fw-semibold">End Time *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="bi bi-clock-fill"></i></span>
                                            <input type="time" name="endTime" id="endTime" class="form-control" value="<%= preEnd != null ? preEnd : "12:00" %>" required>
                                        </div>
                                    </div>
                                    <div class="col-12">
                                        <label for="purpose" class="form-label fw-semibold">Meeting Agenda / Requirements</label>
                                        <textarea name="purpose" id="purpose" class="form-control" rows="2" placeholder="Describe the purpose, projector needs, whiteboard, microphone, etc..."><%= isEdit && editBooking.getPurpose() != null ? editBooking.getPurpose() : "" %></textarea>
                                    </div>
                                </div>

                                <!-- Section 4: Live Price Estimation & Bill Breakdown -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-calculator me-1"></i> 4. Live Pricing &amp; Bill Breakdown
                                </h6>
                                <div class="pricing-calc-box mb-4">
                                    <div class="row align-items-center g-3">
                                        <div class="col-md-8">
                                            <div class="d-flex justify-content-between mb-2">
                                                <span class="text-muted">Estimated Duration:</span>
                                                <strong id="calcHours" class="fw-bold">2.0 hrs</strong>
                                            </div>
                                            <div class="d-flex justify-content-between mb-2">
                                                <span class="text-muted">Room Hourly Rate:</span>
                                                <span id="calcRate" class="fw-semibold">$15.00 / hr</span>
                                            </div>
                                            <div class="d-flex justify-content-between mb-2">
                                                <span class="text-muted">Subtotal:</span>
                                                <span id="calcSubtotal" class="fw-semibold">$30.00</span>
                                            </div>
                                            <div id="calcDiscountRow" class="d-flex justify-content-between mb-2 text-success">
                                                <span><i class="bi bi-tag-fill me-1"></i> Student Discount:</span>
                                                <strong id="calcDiscount" class="fw-bold">-$6.00 (20% Subsidy)</strong>
                                            </div>
                                            <hr class="my-2">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <span class="fs-5 fw-bold text-dark">Total Booking Amount:</span>
                                                <span id="calcTotalAmount" class="fs-3 fw-bold text-primary">$24.00</span>
                                            </div>
                                        </div>
                                        <div class="col-md-4 border-start-md ps-md-4">
                                            <div class="p-3 rounded-3 bg-light border text-center">
                                                <div class="text-muted small mb-1">Pricing Policy</div>
                                                <div class="small text-muted">Billed per hour (minimum 1 hour). Student discounts apply automatically upon checkout!</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Section 5: Payment Options (Online vs Offline) -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-credit-card-2-front me-1"></i> 5. Payment Method &amp; Confirmation Mode
                                </h6>
                                <input type="hidden" name="paymentMethod" id="paymentMethodInput" value="<%= isEdit && editBooking.getPaymentMethod() != null ? editBooking.getPaymentMethod() : "Online - UPI / Card" %>">

                                <div class="row g-3 mb-4">
                                    <!-- Online Option Card -->
                                    <div class="col-md-6">
                                        <div class="payment-method-card selected h-100" id="paymentCardOnline" onclick="selectPaymentMethod('Online - UPI / Card')">
                                            <div class="d-flex align-items-center justify-content-between mb-2">
                                                <div class="d-flex align-items-center gap-2">
                                                    <div class="rounded-circle bg-primary bg-opacity-10 text-primary p-2">
                                                        <i class="bi bi-qr-code-scan fs-4"></i>
                                                    </div>
                                                    <div>
                                                        <h6 class="fw-bold mb-0">Online Payment (Instant QR &bull; Card)</h6>
                                                        <small class="text-muted">UPI QR Code &bull; GPay &bull; PhonePe &bull; Debit/Credit Card</small>
                                                    </div>
                                                </div>
                                                <span class="badge bg-success">Instant PAID Status</span>
                                            </div>
                                            <p class="small text-muted mb-0">Instant online receipt with zero queue. Scan dynamic QR or pay via Card to lock room immediately.</p>
                                        </div>
                                    </div>

                                    <!-- Offline Option Card -->
                                    <div class="col-md-6">
                                        <div class="payment-method-card h-100" id="paymentCardOffline" onclick="selectPaymentMethod('Offline - Pay at Desk')">
                                            <div class="d-flex align-items-center justify-content-between mb-2">
                                                <div class="d-flex align-items-center gap-2">
                                                    <div class="rounded-circle bg-secondary bg-opacity-10 text-secondary p-2">
                                                        <i class="bi bi-shop-window fs-4"></i>
                                                    </div>
                                                    <div>
                                                        <h6 class="fw-bold mb-0">Offline Payment (Pay at Reception)</h6>
                                                        <small class="text-muted">Cash at Desk &bull; POS Terminal &bull; Department Ledger</small>
                                                    </div>
                                                </div>
                                                <span class="badge bg-warning text-dark">Pay at Desk</span>
                                            </div>
                                            <p class="small text-muted mb-0">Reserve room now with status <strong>Pending</strong>. Pay cash or swipe card at the campus/office helpdesk before meeting starts.</p>
                                        </div>
                                    </div>
                                </div>

                                <!-- ONLINE PAYMENT CONTAINER (QR Code & Digital Options) -->
                                <div id="onlinePaymentDetails" class="p-4 rounded-3 border mb-4 bg-body-tertiary">
                                    <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2 flex-wrap gap-2">
                                        <div class="d-flex align-items-center gap-2">
                                            <i class="bi bi-shield-check text-success fs-5"></i>
                                            <h6 class="fw-bold mb-0 text-primary">Instant Online Checkout &bull; UPI QR &amp; Cards</h6>
                                        </div>
                                        <span class="badge bg-success-subtle text-success border border-success-subtle px-3 py-1">
                                            <i class="bi bi-lock-fill me-1"></i> 256-bit Secure Gateway
                                        </span>
                                    </div>

                                    <!-- Sub-tabs for UPI QR vs Card -->
                                    <ul class="nav nav-pills mb-3" id="onlineTabs" role="tablist">
                                        <li class="nav-item" role="presentation">
                                            <button class="nav-link active btn-sm" id="tab-qr-btn" data-bs-toggle="pill" data-bs-target="#tab-qr" type="button" role="tab">
                                                <i class="bi bi-qr-code me-1"></i> Scan UPI QR Code
                                            </button>
                                        </li>
                                        <li class="nav-item" role="presentation">
                                            <button class="nav-link btn-sm" id="tab-card-btn" data-bs-toggle="pill" data-bs-target="#tab-card" type="button" role="tab">
                                                <i class="bi bi-credit-card me-1"></i> Debit / Credit Card
                                            </button>
                                        </li>
                                    </ul>

                                    <div class="tab-content" id="onlineTabsContent">
                                        <!-- UPI QR Code View -->
                                        <div class="tab-pane fade show active" id="tab-qr" role="tabpanel">
                                            <div class="row align-items-center g-3">
                                                <div class="col-auto text-center">
                                                    <div class="p-2 bg-white rounded-3 border shadow-sm d-inline-block">
                                                        <img id="liveQrCodeImg"
                                                             src="https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=upi://pay?pa=meetroom@axisbank&pn=MeetRoom%20Pro&am=24.00&cu=INR" 
                                                             alt="Scan UPI QR" 
                                                             style="width: 150px; height: 150px; display: block;"
                                                             onerror="this.src='https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=MeetRoomBookingPayment';">
                                                        <div class="small fw-bold text-dark mt-1" style="font-size: 0.68rem; letter-spacing: 0.5px;">
                                                            <i class="bi bi-camera me-1"></i> SCAN TO PAY
                                                        </div>
                                                    </div>
                                                </div>
                                                <div class="col">
                                                    <div class="mb-2">
                                                        <span class="badge bg-primary fs-6 px-3 py-1" id="qrPayAmountBadge">Amount to Pay: $24.00</span>
                                                    </div>
                                                    <p class="small text-muted mb-2">
                                                        Open any UPI App (<strong>Google Pay, PhonePe, Paytm, BHIM, Cred</strong>) and scan this QR code to confirm your booking immediately.
                                                    </p>
                                                    <div class="input-group input-group-sm mb-2" style="max-width: 380px;">
                                                        <span class="input-group-text"><i class="bi bi-at"></i> UPI ID</span>
                                                        <input type="text" class="form-control" value="meetroom@axisbank" readonly>
                                                        <button class="btn btn-outline-secondary" type="button" onclick="navigator.clipboard.writeText('meetroom@axisbank'); alert('UPI ID copied!');">
                                                            <i class="bi bi-clipboard"></i> Copy
                                                        </button>
                                                    </div>
                                                    <small class="text-success"><i class="bi bi-check2-circle me-1"></i> Booking slip will automatically be stamped <strong>PAID IN FULL</strong>.</small>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Card View -->
                                        <div class="tab-pane fade" id="tab-card" role="tabpanel">
                                            <div class="row g-2" style="max-width: 500px;">
                                                <div class="col-12">
                                                    <label class="form-label small fw-semibold">Card Number</label>
                                                    <div class="input-group input-group-sm">
                                                        <span class="input-group-text"><i class="bi bi-credit-card"></i></span>
                                                        <input type="text" class="form-control" placeholder="4242 &bull;&bull;&bull;&bull; &bull;&bull;&bull;&bull; 4242" value="4532 8920 1192 4242">
                                                    </div>
                                                </div>
                                                <div class="col-6">
                                                    <label class="form-label small fw-semibold">Expiry Date</label>
                                                    <input type="text" class="form-control form-control-sm" placeholder="MM/YY" value="08/28">
                                                </div>
                                                <div class="col-6">
                                                    <label class="form-label small fw-semibold">CVV / CVC</label>
                                                    <input type="password" class="form-control form-control-sm" placeholder="123" value="982" maxlength="4">
                                                </div>
                                                <div class="col-12 mt-2">
                                                    <small class="text-muted"><i class="bi bi-shield-lock-fill text-success me-1"></i> Simulated gateway accepts Visa, MasterCard, RuPay, Amex.</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- OFFLINE PAYMENT CONTAINER (Counter, POS, Dept Ledger) -->
                                <div id="offlinePaymentDetails" class="p-4 rounded-3 border mb-4 bg-body-tertiary d-none">
                                    <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2 flex-wrap gap-2">
                                        <div class="d-flex align-items-center gap-2">
                                            <i class="bi bi-shop text-warning fs-5"></i>
                                            <h6 class="fw-bold mb-0 text-warning text-dark">Offline Payment Options &bull; Pay at Desk</h6>
                                        </div>
                                        <span class="badge bg-warning text-dark border px-3 py-1">
                                            <i class="bi bi-clock-history me-1"></i> Status: Pending Until Check-In
                                        </span>
                                    </div>

                                    <p class="small text-muted mb-3">
                                        Choose how you wish to pay at the campus / corporate reception counter upon arrival:
                                    </p>

                                    <div class="row g-3 mb-3">
                                        <!-- Option 1: Cash -->
                                        <div class="col-md-4">
                                            <div class="p-3 rounded-3 border bg-body h-100">
                                                <div class="d-flex align-items-center gap-2 mb-2">
                                                    <i class="bi bi-cash-coin fs-4 text-success"></i>
                                                    <strong class="small">1. Cash at Desk</strong>
                                                </div>
                                                <p class="small text-muted mb-0">Pay exact cash amount to the receptionist before occupying the room.</p>
                                            </div>
                                        </div>

                                        <!-- Option 2: POS Card -->
                                        <div class="col-md-4">
                                            <div class="p-3 rounded-3 border bg-body h-100">
                                                <div class="d-flex align-items-center gap-2 mb-2">
                                                    <i class="bi bi-credit-card-2-front fs-4 text-primary"></i>
                                                    <strong class="small">2. POS Terminal Swipe</strong>
                                                </div>
                                                <p class="small text-muted mb-0">Swipe or tap any Debit/Credit card at the front desk POS machine.</p>
                                            </div>
                                        </div>

                                        <!-- Option 3: Dept / Club Voucher -->
                                        <div class="col-md-4">
                                            <div class="p-3 rounded-3 border bg-body h-100">
                                                <div class="d-flex align-items-center gap-2 mb-2">
                                                    <i class="bi bi-journal-check fs-4 text-info"></i>
                                                    <strong class="small">3. Student Club / Dept Ledger</strong>
                                                </div>
                                                <p class="small text-muted mb-0">Charge booking directly to student society or department annual budget voucher.</p>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Desk Location & Timing Notice -->
                                    <div class="p-2 px-3 rounded-3 bg-warning bg-opacity-10 border border-warning border-opacity-25 small text-muted d-flex align-items-center gap-2">
                                        <i class="bi bi-info-circle-fill text-warning fs-5"></i>
                                        <div>
                                            <strong>Reception Location:</strong> Academic Block A, Ground Floor, Room 101 (Open 8:00 AM &ndash; 8:00 PM). Please show your printed reservation slip to collect the room access key.
                                        </div>
                                    </div>
                                </div>

                                <% if (isEdit) { %>
                                    <div class="row g-3 mb-4">
                                        <div class="col-md-6">
                                            <label for="bookingStatus" class="form-label fw-semibold">Reservation Status</label>
                                            <select name="bookingStatus" id="bookingStatus" class="form-select">
                                                <option value="Booked" <%= "Booked".equals(editBooking.getBookingStatus()) ? "selected" : "" %>>Booked</option>
                                                <option value="Completed" <%= "Completed".equals(editBooking.getBookingStatus()) ? "selected" : "" %>>Completed</option>
                                                <option value="Cancelled" <%= "Cancelled".equals(editBooking.getBookingStatus()) ? "selected" : "" %>>Cancelled</option>
                                            </select>
                                        </div>
                                    </div>
                                <% } %>

                                <!-- Actions -->
                                <div class="d-flex justify-content-between align-items-center pt-3 border-top flex-wrap gap-2">
                                    <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-secondary px-4">
                                        <i class="bi bi-x-circle me-1"></i> Cancel
                                    </a>
                                    <button type="submit" class="btn btn-primary btn-lg px-5 fw-bold shadow">
                                        <i class="bi <%= isEdit ? "bi-save" : "bi-check2-circle" %> me-2"></i>
                                        <%= isEdit ? "Save Reservation" : "Confirm Booking & Generate Slip" %>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>

                </div>
            </div>

        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js"></script>
</body>
</html>
