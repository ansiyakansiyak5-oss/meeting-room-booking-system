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
    if (enteredUsername == null || enteredUsername.trim().isEmpty()) {
        enteredUsername = "student";
    }
    String defaultPassword = "student".equalsIgnoreCase(enteredUsername) ? "student123" : ("admin".equalsIgnoreCase(enteredUsername) ? "admin123" : "");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student &amp; Admin Login - MeetRoom Pro</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS (with cache buster) -->
    <link href="<%= request.getContextPath() %>/css/style.css?v=3.2" rel="stylesheet">
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
        .role-btn.active {
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.35) !important;
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
                        <div class="rounded-3 d-flex align-items-center justify-content-center text-white bg-success p-2" style="width: 44px; height: 44px;">
                            <i class="bi bi-mortarboard-fill fs-4"></i>
                        </div>
                        <span class="fs-4 fw-bold text-white tracking-wide">MeetRoom <span class="badge bg-success text-white fs-6">STUDENT PORTAL</span></span>
                    </div>
                </div>

                <div class="position-relative z-1 my-auto py-5">
                    <span class="badge bg-warning text-dark px-3 py-2 fw-bold mb-3 fs-6"><i class="bi bi-mortarboard-fill me-1"></i> Special 20% Student Subsidy Active</span>
                    <h1 class="display-5 fw-bold text-white mb-3">Campus &amp; Conference Room Reservations</h1>
                    <p class="lead text-white-50 mb-4" style="max-width: 580px;">
                        Default student access enabled. Reserve conference halls, seminar rooms, and collaboration huddles with real-time schedule conflict prevention and instant online UPI checkout.
                    </p>
                    <div class="d-flex gap-3 text-white-50 small flex-wrap">
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> 20% Student Discount</div>
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> 4K Display Rooms</div>
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> Campus Wi-Fi &amp; Whiteboards</div>
                        <div><i class="bi bi-check-circle-fill text-success me-1"></i> Instant Invoices &amp; Slips</div>
                    </div>
                </div>

                <div class="position-relative z-1 text-white-50 small">
                    MeetRoom Pro &bull; Pure Java Servlets + JSP + MySQL
                </div>
            </div>

            <!-- Right Form Side -->
            <div class="col-lg-5 login-form-side">
                <div style="max-width: 440px; width: 100%;">
                    
                    <div class="text-center mb-4">
                        <div class="d-inline-flex align-items-center justify-content-center bg-success bg-opacity-10 text-success rounded-circle mb-3" id="loginIconWrapper" style="width: 64px; height: 64px;">
                            <i class="bi bi-mortarboard-fill fs-2" id="loginIcon"></i>
                        </div>
                        <h3 class="fw-bold mb-1" id="loginHeading">Student Portal Login</h3>
                        <p class="text-muted small" id="loginSubheading">Pre-configured with default student credentials &bull; 20% Subsidy</p>
                    </div>

                    <!-- Role Switcher Segmented Control -->
                    <div class="p-1 bg-light rounded-3 d-flex gap-1 mb-4 border" style="background-color: var(--bs-tertiary-bg) !important;">
                        <button type="button" class="btn btn-sm w-50 fw-bold py-2 role-btn <%= "student".equalsIgnoreCase(enteredUsername) ? "btn-success active text-white" : "btn-light text-muted" %>" id="btnStudentRole" onclick="setRole('student')">
                            <i class="bi bi-mortarboard-fill me-1"></i> Student (Default)
                        </button>
                        <button type="button" class="btn btn-sm w-50 fw-bold py-2 role-btn <%= "admin".equalsIgnoreCase(enteredUsername) ? "btn-primary active text-white" : "btn-light text-muted" %>" id="btnAdminRole" onclick="setRole('admin')">
                            <i class="bi bi-shield-lock-fill me-1"></i> Admin Portal
                        </button>
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

                    <!-- Student Subsidy Callout Box -->
                    <div class="alert alert-success d-flex align-items-center mb-3 shadow-sm py-2 px-3 border-0 bg-success bg-opacity-10" id="studentCallout">
                        <i class="bi bi-patch-check-fill text-success fs-4 me-2"></i>
                        <div class="small">
                            <strong>Default Student Account Active:</strong> 20% discount will automatically apply on every room reservation!
                        </div>
                    </div>

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
                                <input type="password" class="form-control" id="password" name="password" value="<%= defaultPassword %>" placeholder="Enter password" required>
                            </div>
                        </div>

                        <div class="d-grid gap-2 mb-3">
                            <button type="submit" id="submitBtn" class="btn <%= "admin".equalsIgnoreCase(enteredUsername) ? "btn-primary" : "btn-success" %> btn-lg fw-bold shadow-sm">
                                <i class="bi <%= "admin".equalsIgnoreCase(enteredUsername) ? "bi-shield-check" : "bi-mortarboard-fill" %> me-1"></i>
                                <span id="submitBtnText"><%= "admin".equalsIgnoreCase(enteredUsername) ? "Sign In as Admin" : "Sign In as Student (Default)" %></span>
                            </button>
                        </div>
                    </form>

                    <!-- Fast Credentials Switcher -->
                    <div class="p-3 rounded-3 border bg-light mt-3" style="background-color: var(--bs-tertiary-bg) !important;">
                        <div class="d-flex align-items-center justify-content-between mb-2">
                            <div class="small fw-bold"><i class="bi bi-key-fill text-success me-1"></i> Quick 1-Click Credentials:</div>
                            <span class="badge bg-success">Ready</span>
                        </div>
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-sm btn-outline-success flex-grow-1 text-start" onclick="setRole('student')">
                                <div class="fw-bold"><i class="bi bi-mortarboard-fill me-1"></i> Student (Default)</div>
                                <div class="font-monospace small text-muted">student / student123</div>
                            </button>
                            <button type="button" class="btn btn-sm btn-outline-primary flex-grow-1 text-start" onclick="setRole('admin')">
                                <div class="fw-bold"><i class="bi bi-shield-lock-fill me-1"></i> Admin</div>
                                <div class="font-monospace small text-muted">admin / admin123</div>
                            </button>
                        </div>
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
    <script>
        function setRole(role) {
            const userInput = document.getElementById('username');
            const passInput = document.getElementById('password');
            const submitBtn = document.getElementById('submitBtn');
            const submitBtnText = document.getElementById('submitBtnText');
            const btnStudent = document.getElementById('btnStudentRole');
            const btnAdmin = document.getElementById('btnAdminRole');
            const iconWrapper = document.getElementById('loginIconWrapper');
            const icon = document.getElementById('loginIcon');
            const heading = document.getElementById('loginHeading');
            const subheading = document.getElementById('loginSubheading');
            const callout = document.getElementById('studentCallout');

            if (role === 'admin') {
                userInput.value = 'admin';
                passInput.value = 'admin123';
                submitBtn.className = 'btn btn-primary btn-lg fw-bold shadow-sm';
                submitBtn.querySelector('i').className = 'bi bi-shield-check me-1';
                submitBtnText.textContent = 'Sign In as Admin';
                
                btnAdmin.className = 'btn btn-sm w-50 fw-bold py-2 role-btn btn-primary active text-white';
                btnStudent.className = 'btn btn-sm w-50 fw-bold py-2 role-btn btn-light text-muted';
                
                iconWrapper.className = 'd-inline-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary rounded-circle mb-3';
                icon.className = 'bi bi-shield-lock-fill fs-2';
                heading.textContent = 'Admin Portal Login';
                subheading.textContent = 'Full administrative control over rooms, schedules & rates';
                if (callout) callout.style.display = 'none';
            } else {
                userInput.value = 'student';
                passInput.value = 'student123';
                submitBtn.className = 'btn btn-success btn-lg fw-bold shadow-sm';
                submitBtn.querySelector('i').className = 'bi bi-mortarboard-fill me-1';
                submitBtnText.textContent = 'Sign In as Student (Default)';
                
                btnStudent.className = 'btn btn-sm w-50 fw-bold py-2 role-btn btn-success active text-white';
                btnAdmin.className = 'btn btn-sm w-50 fw-bold py-2 role-btn btn-light text-muted';
                
                iconWrapper.className = 'd-inline-flex align-items-center justify-content-center bg-success bg-opacity-10 text-success rounded-circle mb-3';
                icon.className = 'bi bi-mortarboard-fill fs-2';
                heading.textContent = 'Student Portal Login';
                subheading.textContent = 'Pre-configured with default student credentials \u2022 20% Subsidy';
                if (callout) callout.style.display = 'flex';
            }
        }
    </script>
    <script src="<%= request.getContextPath() %>/js/script.js?v=3.2"></script>
</body>
</html>
