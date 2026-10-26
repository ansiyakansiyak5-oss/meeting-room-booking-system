<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // If already logged in, redirect to dashboard
    if (session.getAttribute("user") != null) {
        response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
        return;
    }
    String error = (String) request.getAttribute("errorMessage");
    String msg = request.getParameter("msg");
    String enteredUsername = (String) request.getAttribute("enteredUsername");
    if (enteredUsername == null) enteredUsername = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - MeetRoom Pro</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS (with cache buster) -->
    <link href="<%= request.getContextPath() %>/css/style.css?v=3.1" rel="stylesheet">
    <style>
        .login-hero-container {
            min-height: 100vh;
            display: flex;
            align-items: stretch;
            background: #0f172a;
        }
        .login-visual-side {
            position: relative;
            background-size: cover;
            background-position: center;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 3rem;
            color: #ffffff;
        }
        .login-form-side {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2.5rem;
            background: #ffffff;
        }
        [data-bs-theme="dark"] .login-form-side {
            background: #0b1120;
            color: #f1f5f9;
        }
    </style>
</head>
<body>

    <div class="login-hero-container">
        <div class="row g-0 w-100 min-vh-100">
            <!-- Left Visual Side with Meeting Room Picture -->
            <div class="col-lg-7 d-none d-lg-flex login-visual-side position-relative overflow-hidden">
                <img src="<%= request.getContextPath() %>/images/meeting-room-hero.jpg" alt="Meeting Room" class="position-absolute top-0 start-0 w-100 h-100" style="object-fit: cover; filter: brightness(0.38);">
                
                <div class="position-relative z-1">
                    <div class="d-flex align-items-center gap-2">
                        <div class="rounded-3 d-flex align-items-center justify-content-center text-white bg-primary p-2" style="width: 44px; height: 44px;">
                            <i class="bi bi-building-check fs-4"></i>
                        </div>
                        <span class="fs-4 fw-bold text-white tracking-wide">MeetRoom <span class="badge bg-primary text-white fs-6">PRO</span></span>
                    </div>
                </div>

                <div class="position-relative z-1 my-auto py-5">
                    <span class="badge bg-warning text-dark px-3 py-2 fw-bold mb-3"><i class="bi bi-mortarboard-fill me-1"></i> Special 20% Student Subsidy</span>
                    <h1 class="display-5 fw-bold text-white mb-3">Enterprise &amp; Campus Meeting Room Booking</h1>
                    <p class="lead text-white-50 mb-4" style="max-width: 580px;">
                        Zero double-booking guarantee with real-time schedule conflict prevention, hourly billing, and instant Online UPI / Card payment.
                    </p>
                    <div class="d-flex gap-3 text-white-50 small flex-wrap">
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> 4K Display Rooms</div>
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> High-Speed Campus Wi-Fi</div>
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> Video Conferencing</div>
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> Instant Invoices &amp; Slips</div>
                    </div>
                </div>

                <div class="position-relative z-1 text-white-50 small">
                    Pure Java Servlets + JSP + MySQL &bull; Meeting Room System
                </div>
            </div>

            <!-- Right Form Side -->
            <div class="col-lg-5 login-form-side">
                <div style="max-width: 420px; width: 100%;">
                    
                    <div class="text-center mb-4">
                        <div class="d-inline-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary rounded-circle mb-3" style="width: 60px; height: 60px;">
                            <i class="bi bi-shield-lock-fill fs-2"></i>
                        </div>
                        <h3 class="fw-bold mb-1">Account Sign In</h3>
                        <p class="text-muted small">Enter your credentials to access room reservation system</p>
                    </div>

                    <% if (error != null && !error.isEmpty()) { %>
                        <div class="alert alert-danger alert-dismissible fade show shadow-sm" role="alert">
                            <i class="bi bi-exclamation-triangle-fill me-2"></i><%= error %>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    <% } %>

                    <% if ("logged_out".equals(msg)) { %>
                        <div class="alert alert-success alert-dismissible fade show shadow-sm" role="alert">
                            <i class="bi bi-check-circle-fill me-2"></i>You have been logged out successfully.
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    <% } else if ("auth_required".equals(msg)) { %>
                        <div class="alert alert-warning alert-dismissible fade show shadow-sm" role="alert">
                            <i class="bi bi-lock-fill me-2"></i>Please log in to access this page.
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    <% } %>

                    <form action="<%= request.getContextPath() %>/login" method="post" id="loginForm">
                        <div class="mb-3">
                            <label for="username" class="form-label fw-semibold">Username</label>
                            <div class="input-group input-group-lg">
                                <span class="input-group-text"><i class="bi bi-person"></i></span>
                                <input type="text" class="form-control" id="username" name="username" value="<%= enteredUsername %>" placeholder="Enter username" required autofocus>
                            </div>
                        </div>

                        <div class="mb-4">
                            <label for="password" class="form-label fw-semibold">Password</label>
                            <div class="input-group input-group-lg">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                                <input type="password" class="form-control" id="password" name="password" placeholder="Enter password" required>
                            </div>
                        </div>

                        <div class="d-grid gap-2 mb-3">
                            <button type="submit" class="btn btn-primary btn-lg fw-bold shadow-sm">
                                <i class="bi bi-box-arrow-in-right me-1"></i> Sign In to Portal
                            </button>
                        </div>
                    </form>

                    <div class="p-3 rounded-3 text-center border bg-light mt-3">
                        <div class="small text-muted mb-1"><i class="bi bi-key-fill text-primary me-1"></i><strong>Default Admin Credentials:</strong></div>
                        <div class="small font-monospace">Username: <span class="badge bg-secondary">admin</span> &nbsp;|&nbsp; Password: <span class="badge bg-secondary">admin123</span></div>
                    </div>

                    <div class="text-center mt-4 text-muted small">
                        MeetRoom Pro &bull; Cloud Database Powered by MySQL
                    </div>

                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js?v=3.1"></script>
</body>
</html>
