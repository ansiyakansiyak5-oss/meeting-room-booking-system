<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String sidebarUsername = (String) session.getAttribute("user");
    if (sidebarUsername == null) {
        sidebarUsername = "Guest";
    }
    String sidebarRequestUri = request.getRequestURI();
%>
<script>
    // Apply saved theme immediately before render to avoid flash
    (function() {
        const savedTheme = localStorage.getItem('meetroom_theme') || 'light';
        document.documentElement.setAttribute('data-bs-theme', savedTheme);
    })();
</script>

<style>
    /* Critical Sidebar Styles to prevent FOUC / cache issues */
    .app-sidebar {
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        bottom: 0 !important;
        width: 260px !important;
        height: 100vh !important;
        background-color: #0f172a !important;
        color: #e2e8f0 !important;
        z-index: 1045 !important;
        display: flex !important;
        flex-direction: column !important;
        box-shadow: 4px 0 20px rgba(0, 0, 0, 0.25) !important;
        transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
        overflow: hidden !important;
    }
    .main-content {
        min-height: 100vh;
        transition: margin-left 0.3s ease;
    }
    @media (min-width: 992px) {
        .main-content {
            margin-left: 260px !important;
        }
    }
    @media (max-width: 991.98px) {
        .app-sidebar {
            transform: translateX(-100%) !important;
        }
        .app-sidebar.show {
            transform: translateX(0) !important;
        }
    }
    .sidebar-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.6);
        backdrop-filter: blur(2px);
        z-index: 1042;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.3s ease, visibility 0.3s ease;
    }
    .sidebar-overlay.show {
        opacity: 1;
        visibility: visible;
    }
    .app-sidebar a.nav-link {
        color: #94a3b8 !important;
        padding: 0.65rem 1rem !important;
        border-radius: 8px !important;
        display: flex !important;
        align-items: center !important;
        transition: all 0.2s ease !important;
        text-decoration: none !important;
    }
    .app-sidebar a.nav-link:hover {
        color: #ffffff !important;
        background-color: rgba(255, 255, 255, 0.08) !important;
    }
    .app-sidebar a.nav-link.active {
        color: #ffffff !important;
        background: linear-gradient(90deg, #2563eb 0%, #1d4ed8 100%) !important;
        font-weight: 600 !important;
        box-shadow: 0 4px 12px rgba(37, 99, 235, 0.35) !important;
    }
    .online-indicator {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background-color: #10b981;
        display: inline-block;
        box-shadow: 0 0 8px #10b981;
    }
    @media print {
        .app-sidebar, .mobile-topbar, .sidebar-overlay, .no-print {
            display: none !important;
        }
        .main-content {
            margin-left: 0 !important;
            padding: 0 !important;
        }
    }
</style>

<!-- Mobile Top Navigation Bar -->
<div class="mobile-topbar d-lg-none d-flex align-items-center justify-content-between px-3 py-2 border-bottom bg-body">
    <div class="d-flex align-items-center gap-2">
        <button class="btn btn-outline-secondary btn-sm p-1 px-2" type="button" onclick="toggleSidebar()" aria-label="Toggle Navigation">
            <i class="bi bi-list fs-5"></i>
        </button>
        <a class="navbar-brand d-flex align-items-center fw-bold text-decoration-none text-primary" href="<%= request.getContextPath() %>/dashboard.jsp">
            <i class="bi bi-building-check me-2 fs-4"></i>
            <span>MeetRoom <span class="badge bg-primary text-white fs-6">Pro</span></span>
        </a>
    </div>
    <div class="d-flex align-items-center gap-2">
        <button class="btn btn-sm btn-outline-secondary theme-toggle-btn" onclick="toggleTheme()" title="Switch Theme">
            <i class="bi bi-sun-fill theme-icon-light d-none"></i>
            <i class="bi bi-moon-stars-fill theme-icon-dark"></i>
        </button>
        <a href="<%= request.getContextPath() %>/logout" class="btn btn-sm btn-outline-danger" title="Logout">
            <i class="bi bi-box-arrow-right"></i>
        </a>
    </div>
</div>

<!-- Backdrop overlay for mobile drawer -->
<div class="sidebar-overlay d-lg-none" id="sidebarOverlay" onclick="toggleSidebar()"></div>

<!-- Left Main Menu Sidebar -->
<aside class="app-sidebar no-print" id="appSidebar">
    <!-- Brand Logo -->
    <div class="sidebar-brand px-4 py-3 d-flex align-items-center justify-content-between border-bottom border-secondary border-opacity-25" style="background: rgba(0,0,0,0.25); min-height: 64px;">
        <a href="<%= request.getContextPath() %>/dashboard.jsp" class="d-flex align-items-center text-decoration-none">
            <div class="brand-icon me-2 rounded-3 d-flex align-items-center justify-content-center text-white bg-primary shadow-sm" style="width: 38px; height: 38px; background: linear-gradient(135deg, #2563eb, #1d4ed8);">
                <i class="bi bi-building-check fs-5"></i>
            </div>
            <div>
                <span class="fs-5 fw-bold text-white tracking-wide">MeetRoom</span>
                <span class="badge bg-primary text-white ms-1" style="font-size: 0.65rem; vertical-align: middle;">PRO</span>
            </div>
        </a>
        <button class="btn btn-link text-white-50 p-0 d-lg-none" onclick="toggleSidebar()">
            <i class="bi bi-x-lg fs-5"></i>
        </button>
    </div>

    <!-- User Profile Badge -->
    <div class="sidebar-user px-4 py-3 border-bottom border-secondary border-opacity-25">
        <div class="d-flex align-items-center">
            <div class="avatar-circle me-3 bg-primary bg-opacity-25 text-primary border border-primary border-opacity-50 rounded-circle d-flex align-items-center justify-content-center fw-bold" style="width: 42px; height: 42px; font-size: 1.1rem;">
                <%= sidebarUsername.length() > 0 ? sidebarUsername.substring(0, 1).toUpperCase() : "U" %>
            </div>
            <div class="overflow-hidden">
                <div class="text-white fw-semibold text-truncate small mb-0"><%= sidebarUsername %></div>
                <div class="d-flex align-items-center gap-1">
                    <span class="online-indicator"></span>
                    <span class="text-white-50" style="font-size: 0.75rem;">Active &bull; Verified</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Navigation Menu -->
    <div class="sidebar-menu-wrapper flex-grow-1 py-3 px-3 overflow-y-auto">
        <div class="sidebar-section-title px-3 text-uppercase text-white-50 fw-bold small mb-2" style="font-size: 0.7rem; letter-spacing: 0.08em;">
            Main Navigation
        </div>
        <ul class="nav flex-column gap-1 mb-3">
            <li class="nav-item">
                <a class="nav-link <%= sidebarRequestUri.endsWith("dashboard.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/dashboard.jsp">
                    <i class="bi bi-grid-1x2-fill me-2"></i>
                    <span>Dashboard</span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <%= sidebarRequestUri.contains("rooms") || sidebarRequestUri.endsWith("room-management.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/rooms">
                    <i class="bi bi-door-open-fill me-2"></i>
                    <span>Room Management</span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <%= sidebarRequestUri.contains("bookings") || sidebarRequestUri.endsWith("booking.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/bookings">
                    <i class="bi bi-calendar-plus-fill me-2"></i>
                    <span>Book a Room</span>
                    <span class="badge bg-success ms-auto" style="font-size: 0.65rem;">New</span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <%= sidebarRequestUri.contains("availability") || sidebarRequestUri.endsWith("availability.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/availability">
                    <i class="bi bi-search-heart-fill me-2"></i>
                    <span>Room Availability</span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <%= sidebarRequestUri.contains("history") || sidebarRequestUri.endsWith("history.jsp") || sidebarRequestUri.contains("receipt") ? "active" : "" %>" href="<%= request.getContextPath() %>/history">
                    <i class="bi bi-receipt-cutoff me-2"></i>
                    <span>Booking &amp; Invoices</span>
                </a>
            </li>
        </ul>

        <!-- Student & Corporate Perks Box -->
        <div class="perk-card p-3 rounded-3 mx-1 mb-3" style="background: rgba(30, 41, 59, 0.7); border: 1px solid rgba(245, 158, 11, 0.35);">
            <div class="d-flex align-items-center mb-1 text-warning fw-semibold small">
                <i class="bi bi-mortarboard-fill me-1"></i> Student 20% Subsidy
            </div>
            <p class="text-white-50 mb-0" style="font-size: 0.75rem; line-height: 1.35;">
                College students &amp; clubs get <strong>20% discount</strong> automatically applied at checkout!
            </p>
        </div>
    </div>

    <!-- Sidebar Footer / Theme & Logout -->
    <div class="sidebar-footer p-3 border-top border-secondary border-opacity-25" style="background: rgba(0,0,0,0.25);">
        <div class="d-flex align-items-center justify-content-between mb-2">
            <span class="text-white-50 small"><i class="bi bi-palette2 me-1"></i> Theme</span>
            <button class="btn btn-sm btn-dark border border-secondary text-white rounded-pill px-3 py-1 theme-toggle-btn" onclick="toggleTheme()" title="Switch Light/Dark Mode">
                <span class="theme-text-light d-none"><i class="bi bi-sun-fill text-warning me-1"></i> Light</span>
                <span class="theme-text-dark"><i class="bi bi-moon-stars-fill text-info me-1"></i> Dark</span>
            </button>
        </div>
        <a href="<%= request.getContextPath() %>/logout" class="btn btn-outline-danger btn-sm w-100 d-flex align-items-center justify-content-center gap-1">
            <i class="bi bi-box-arrow-right"></i>
            <span>Sign Out</span>
        </a>
    </div>
</aside>
