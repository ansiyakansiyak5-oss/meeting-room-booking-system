package com.meetingroom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.BufferedReader;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Intelligent AI Chatbot Servlet for Meeting Room Booking System (MRBS).
 * 
 * Supports:
 * 1. Google Gemini API (default, configurable via AI_API_KEY / GEMINI_API_KEY).
 * 2. OpenAI API (configurable via AI_PROVIDER=openai and OPENAI_API_KEY).
 * 3. Intelligent Local Knowledge Engine (fallback when no API key is set or network is unreachable).
 * 4. Contextual MRBS booking details & role-aware assistance (Student vs Admin).
 * 5. Academic & Computer Science doubts support.
 * 6. Rate limiting & input length validation to prevent abuse.
 */
@WebServlet(urlPatterns = {"/api/chat", "/chat"})
public class ChatServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Rate limiter storage: IP/Session -> last request timestamp
    private static final Map<String, Long> rateLimitMap = new ConcurrentHashMap<>();
    private static final long MIN_REQUEST_INTERVAL_MS = 1000; // 1 second interval

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"status\":\"active\",\"service\":\"MRBS AI Assistant API\",\"version\":\"1.0\"}");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        String clientIdentifier = (session != null) ? session.getId() : request.getRemoteAddr();

        // 1. Rate Limiting Check
        long now = System.currentTimeMillis();
        Long lastTime = rateLimitMap.get(clientIdentifier);
        if (lastTime != null && (now - lastTime) < MIN_REQUEST_INTERVAL_MS) {
            sendJsonResponse(response, 429, false,
                    "You are sending messages too quickly. Please wait a moment.", "rate_limited");
            return;
        }
        rateLimitMap.put(clientIdentifier, now);

        // 2. Parse User Message
        String userMessage = extractMessage(request);
        if (userMessage == null || userMessage.trim().isEmpty()) {
            sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST, false,
                    "Message cannot be empty. Please enter your question.", "validation_error");
            return;
        }

        userMessage = userMessage.trim();
        if (userMessage.length() > 1000) {
            sendJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST, false,
                    "Message is too long. Please limit your question to 1,000 characters.", "validation_error");
            return;
        }

        // 3. Resolve Current Session Role & User Context
        String currentUser = (session != null && session.getAttribute("user") != null)
                ? (String) session.getAttribute("user")
                : "Guest";
        String currentRole = (session != null && session.getAttribute("role") != null)
                ? (String) session.getAttribute("role")
                : ("student".equalsIgnoreCase(currentUser) ? "Student" : ("admin".equalsIgnoreCase(currentUser) ? "Admin" : "Visitor"));

        // 4. Check for User-Specific Booking Inquiries (Secured: Only current user's data)
        String userBookingsSummary = null;
        if (!"Guest".equalsIgnoreCase(currentUser)) {
            userBookingsSummary = fetchUserBookingsSummary(currentUser, currentRole);
        }

        // 5. Build Knowledge Base / System Prompt
        String systemInstruction = buildSystemPrompt(currentUser, currentRole, userBookingsSummary);

        // 6. Attempt Real AI API Call (Gemini or OpenAI)
        String apiKey = getEnvOrProp("AI_API_KEY", getEnvOrProp("GEMINI_API_KEY", getEnvOrProp("OPENAI_API_KEY", null)));
        String provider = getEnvOrProp("AI_PROVIDER", "gemini").toLowerCase();
        String model = getEnvOrProp("AI_MODEL", "gemini-1.5-flash");

        String aiReply = null;
        String usedProvider = "local_engine";

        if (apiKey != null && !apiKey.trim().isEmpty() && !apiKey.equalsIgnoreCase("your_api_key_here") && !apiKey.equalsIgnoreCase("your_gemini_or_openai_api_key_here")) {
            try {
                if ("openai".equals(provider)) {
                    aiReply = callOpenAI(apiKey, model, systemInstruction, userMessage);
                    if (aiReply != null && !aiReply.trim().isEmpty()) {
                        usedProvider = "openai (" + model + ")";
                    }
                } else {
                    aiReply = callGemini(apiKey, model, systemInstruction, userMessage);
                    if (aiReply != null && !aiReply.trim().isEmpty()) {
                        usedProvider = "gemini (" + model + ")";
                    }
                }
            } catch (Exception e) {
                System.err.println("[ChatServlet] AI API call exception (" + e.getMessage() + "). Falling back to Local Knowledge Engine.");
            }
        }

        // 7. Fallback to Local MRBS Knowledge Engine if API is unavailable or returned null
        if (aiReply == null || aiReply.trim().isEmpty()) {
            aiReply = generateLocalResponse(userMessage, currentUser, currentRole, userBookingsSummary);
            usedProvider = "local_knowledge_engine";
        }

        // Guarantee response is never null or blank
        if (aiReply == null || aiReply.trim().isEmpty()) {
            aiReply = "I am your MRBS Assistant. You can ask me how to book rooms, check free slots, 20% student subsidies, or manage bookings!";
        }

        // 8. Return JSON Response
        sendJsonResponse(response, HttpServletResponse.SC_OK, true, aiReply, usedProvider);
    }

    /**
     * Calls Google Gemini API using native java.net.http.HttpClient.
     */
    private String callGemini(String apiKey, String model, String systemInstruction, String userMessage) throws Exception {
        String url = String.format("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
                model, apiKey);

        String combinedPrompt = systemInstruction + "\n\nUser Question: " + userMessage;
        String escapedPrompt = escapeJsonString(combinedPrompt);

        String jsonPayload = "{\"contents\":[{\"parts\":[{\"text\":\"" + escapedPrompt + "\"}]}]}";

        HttpRequest httpRequest = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(15))
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> httpResponse = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());

        if (httpResponse.statusCode() == 200) {
            return parseGeminiReply(httpResponse.body());
        } else {
            System.err.println("[ChatServlet] Gemini API returned HTTP " + httpResponse.statusCode() + ": " + httpResponse.body());
            return null;
        }
    }

    /**
     * Calls OpenAI API using native java.net.http.HttpClient.
     */
    private String callOpenAI(String apiKey, String model, String systemInstruction, String userMessage) throws Exception {
        String url = "https://api.openai.com/v1/chat/completions";

        String jsonPayload = String.format(
                "{\"model\":\"%s\",\"messages\":[" +
                        "{\"role\":\"system\",\"content\":\"%s\"}," +
                        "{\"role\":\"user\",\"content\":\"%s\"}" +
                        "],\"temperature\":0.7,\"max_tokens\":600}",
                model,
                escapeJsonString(systemInstruction),
                escapeJsonString(userMessage)
        );

        HttpRequest httpRequest = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + apiKey)
                .timeout(Duration.ofSeconds(15))
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> httpResponse = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());

        if (httpResponse.statusCode() == 200) {
            return parseOpenAIReply(httpResponse.body());
        } else {
            System.err.println("[ChatServlet] OpenAI API returned HTTP " + httpResponse.statusCode() + ": " + httpResponse.body());
            return null;
        }
    }

    /**
     * Intelligent local fallback knowledge engine for MRBS.
     * Answers common student/admin queries, Manglish questions, academic doubts, and navigational doubts accurately.
     */
    private String generateLocalResponse(String message, String currentUser, String currentRole, String userBookings) {
        String lower = message.toLowerCase();

        // 1. My Bookings / Status
        if (lower.contains("my booking") || lower.contains("my reservation") || lower.contains("check my room") || lower.contains("ente booking")) {
            if ("Guest".equalsIgnoreCase(currentUser)) {
                return "To view your active bookings, please **Sign In** with your student account first at the login page.";
            }
            if (userBookings != null && !userBookings.isEmpty()) {
                return "Here is your current reservation status:\n" + userBookings +
                        "\n\nYou can manage or cancel reservations anytime on the **[Booking History & Invoices](/history)** page.";
            } else {
                return "You do not have any active reservations booked yet under account **" + currentUser + "**.\n\n" +
                        "Would you like to reserve a conference or seminar hall? You can book one right now on the **[Book a Room](/bookings)** page with your **20% Student Subsidy**!";
            }
        }

        // 2. Student Discount / Pricing
        if (lower.contains("discount") || lower.contains("subsidy") || lower.contains("student rate") || lower.contains("price") || lower.contains("cost") || lower.contains("fees") || lower.contains("paisa") || lower.contains("rate")) {
            return "**🎓 Special 20% Student Subsidy Information:**\n" +
                    "- All verified college students and registered student clubs receive an automatic **20% discount** on all room reservations!\n" +
                    "- **Current Rates with Subsidy:**\n" +
                    "  • **HR-301 Innovation Huddle (6 seats):** $8.00/hr (Reg. $10)\n" +
                    "  • **MR-404 Genesis Collaboration (10 seats):** $12.00/hr (Reg. $15)\n" +
                    "  • **CR-101 Apollo Conference Hall (20 seats):** $20.00/hr (Reg. $25)\n" +
                    "  • **MR-202 Executive Boardroom (12 seats):** $24.00/hr (Reg. $30)\n" +
                    "  • **CR-105 Orion Auditorium (30 seats):** $32.00/hr (Reg. $40)\n" +
                    "- Simply select **College Student** in the booking form, and the 20% discount applies immediately at checkout.";
        }

        // 3. How to Book a Room
        if (lower.contains("how to book") || lower.contains("how do i book") || lower.contains("reserve") || lower.contains("book cheyyam") || lower.contains("book cheyyuka") || lower.contains("room booking steps") || lower.contains("engane book")) {
            return "**📋 How to Book a Meeting Room in 4 Quick Steps:**\n" +
                    "1. Navigate to **[Book a Room](/bookings)** in the navigation menu.\n" +
                    "2. Select your category (**College Student (20% Subsidy)** is selected by default).\n" +
                    "3. Choose your desired Meeting Room, Meeting Date, Start Time, and End Time.\n" +
                    "4. Choose your payment method (**Online UPI QR** or **Offline Counter**) and click **Confirm & Reserve Room**.\n\n" +
                    "Your booking slip and invoice will be generated instantly with zero double-booking conflict guaranteed!";
        }

        // 4. Room Availability / Free Slots
        if (lower.contains("available") || lower.contains("free room") || lower.contains("check availability") || lower.contains("room undo") || lower.contains("slot")) {
            return "**🔍 Checking Free Room Slots:**\n" +
                    "You can check real-time availability on the **[Room Availability](/availability)** page.\n" +
                    "- Enter your desired date, start time, end time, and required capacity.\n" +
                    "- The system will filter out rooms that are already booked and show you all verified open rooms.\n" +
                    "- Click **'Book This Room'** directly from the results to reserve it immediately!";
        }

        // 5. Cancel or Modify Reservation
        if (lower.contains("cancel") || lower.contains("modify") || lower.contains("edit") || lower.contains("change time") || lower.contains("delete")) {
            return "**🔄 Cancelling or Modifying a Reservation:**\n" +
                    "- Go to the **[Booking & Invoices](/history)** page.\n" +
                    "- Locate your reservation in the list.\n" +
                    "- Click the **Edit (✏️)** button to adjust date/time, or click **Cancel (❌)** to release the room slot immediately.\n" +
                    "- The room will be made available for other campus students and staff right away.";
        }

        // 6. Booking History / Invoices
        if (lower.contains("history") || lower.contains("where can i see") || lower.contains("past booking") || lower.contains("receipt") || lower.contains("invoice") || lower.contains("slip")) {
            return "**📑 Where to View Your Booking History & Invoices:**\n" +
                    "- Click on **[Booking & Invoices](/history)** in the left sidebar menu.\n" +
                    "- Here you will find all your upcoming, completed, and cancelled reservations.\n" +
                    "- Click the **Receipt / Invoice** icon next to any booking to view or print an official PDF invoice containing payment breakdown, tax details, and booking reference ID.";
        }

        // 7. Contact Administrator
        if (lower.contains("contact") || lower.contains("administrator") || lower.contains("helpdesk") || lower.contains("support") || lower.contains("reach admin") || lower.contains("phone") || lower.contains("email")) {
            return "**📞 How to Contact the Campus Administrator:**\n" +
                    "- **Office Location:** Campus Administration Block, 1st Floor, Room 102.\n" +
                    "- **Helpdesk Extension:** Ext. 4040 / (+91) 98765-43210.\n" +
                    "- **Support Email:** `mrbs-support@campus.edu`\n" +
                    "- **Operating Hours:** Monday to Friday, 08:30 AM – 05:30 PM.\n" +
                    "- For urgent room key access or projector support, visit the Ground Floor Security Desk.";
        }

        // 8. Login / Credentials
        if (lower.contains("login") || lower.contains("sign in") || lower.contains("credential") || lower.contains("password") || lower.contains("account") || lower.contains("student login")) {
            return "**🔑 Account Sign In Information:**\n" +
                    "- **Default Student Login:**\n" +
                    "  • Username: `student`\n" +
                    "  • Password: `student123`\n" +
                    "  *(Student portal opens by default with 20% discount active!)*\n" +
                    "- **Admin Login:**\n" +
                    "  • Username: `admin`\n" +
                    "  • Password: `admin123`\n" +
                    "  *(Provides full control over room creation, schedule management, and rates.)*";
        }

        // 9. Conflict Prevention & Rules
        if (lower.contains("conflict") || lower.contains("double book") || lower.contains("rules") || lower.contains("overlap") || lower.contains("clash")) {
            return "**🛡️ Smart Schedule Conflict Prevention:**\n" +
                    "- MeetRoom Pro features a strict zero-double-booking policy.\n" +
                    "- If another student or faculty member has booked a room for even 1 overlapping minute on the same date, the system prevents double-booking and alerts you with the conflicting reservation details.\n" +
                    "- Meetings can be reserved from **08:00 AM to 08:00 PM** in 30-minute or 1-hour intervals.";
        }

        // 10. Payment Methods (UPI & Offline)
        if (lower.contains("payment") || lower.contains("upi") || lower.contains("qr") || lower.contains("cash") || lower.contains("pay") || lower.contains("gpay") || lower.contains("phonepe")) {
            return "**💳 Supported Payment Options:**\n" +
                    "1. **Instant Online UPI QR:** Scan with Google Pay, PhonePe, Paytm, or any UPI app for instant confirmation.\n" +
                    "2. **Admin Cash Desk:** Pay cash directly at Campus Admin Block Room 102.\n" +
                    "3. **Student Affairs Desk:** Pay via Student Wallet/Desk in the Tech Center.\n" +
                    "4. **Campus Bank Counter:** Pay at the Union Bank campus counter.\n\n" +
                    "All methods generate an official downloadable invoice and reservation slip!";
        }

        // 11. Computer Science & Academic Doubts
        if (lower.contains("algorithm")) {
            return "**📘 Computer Science: What is an Algorithm?**\n" +
                    "An algorithm is a finite, step-by-step sequence of well-defined instructions designed to solve a specific problem or compute a result.\n" +
                    "- **Key Properties:** Finiteness, Definiteness, Input, Output, and Effectiveness.\n" +
                    "- **MRBS Example:** Our interval overlap algorithm checks `(start_time < existing_end) AND (end_time > existing_start)` to guarantee zero double-bookings in $O(1)$ query time.";
        }

        if (lower.contains("oop") || lower.contains("object oriented")) {
            return "**📘 Computer Science: 4 Pillars of Object-Oriented Programming (OOP):**\n" +
                    "1. **Encapsulation:** Bundling data and methods into single units (e.g., our `Room` and `Booking` Java model classes).\n" +
                    "2. **Abstraction:** Hiding complex internal logic and exposing clean interfaces (e.g., `DatabaseConnection.getConnection()`).\n" +
                    "3. **Inheritance:** Enabling a class to acquire properties of another class (`HttpServlet` extended by `BookingServlet`).\n" +
                    "4. **Polymorphism:** Allowing methods to take different forms based on object types.";
        }

        if (lower.contains("database") || lower.contains("sql") || lower.contains("dbms")) {
            return "**📘 Computer Science: Databases & SQL:**\n" +
                    "- **DBMS:** Software that manages databases with ACID properties (Atomicity, Consistency, Isolation, Durability).\n" +
                    "- **SQL:** Standard language used for querying relational databases (`SELECT`, `INSERT`, `UPDATE`, `DELETE`).\n" +
                    "- In MRBS, we use MySQL with parameterized `PreparedStatement` queries to prevent SQL injection vulnerabilities.";
        }

        if (lower.contains("what is java") || lower.contains("explain java")) {
            return "**📘 Computer Science: What is Java?**\n" +
                    "Java is a high-level, class-based, object-oriented programming language designed for platform independence via the Java Virtual Machine (JVM) — 'Write Once, Run Anywhere' (WORA).\n" +
                    "In MRBS, Java Servlets running on Apache Tomcat process HTTP requests and orchestrate backend business logic.";
        }

        // 12. Greetings (supports English & Malayalam/Manglish)
        if (lower.contains("hi") || lower.contains("hello") || lower.contains("hey") || lower.contains("namaskaram") || lower.contains("hai")) {
            return "Hello" + ("Guest".equalsIgnoreCase(currentUser) ? "" : " **" + currentUser + "**") + "! 👋\n\n" +
                    "I am your **MRBS AI Assistant**. You can ask me anything about:\n" +
                    "- 📅 Checking free meeting room slots & schedules\n" +
                    "- 🎓 20% Student Subsidy rates & discounts\n" +
                    "- 📋 How to book, edit, or cancel a room\n" +
                    "- 💳 Online UPI QR & offline payment counters\n" +
                    "- 📑 Viewing invoices and booking receipts\n" +
                    "- 📘 Computer science & academic questions\n\n" +
                    "How can I assist you right now?";
        }

        // Default Helpful Response
        return "I'm here to help with your campus meeting room reservations and academic questions! You can ask me:\n\n" +
                "- *'How do I book a meeting room?'*\n" +
                "- *'What is the student discount rate?'*\n" +
                "- *'How can I check available rooms?'*\n" +
                "- *'Where can I see my booking history?'*\n" +
                "- *'How do I cancel a booking?'*\n" +
                "- *'How can I contact the administrator?'*\n" +
                "- *'What is an algorithm / OOP?'*\n\n" +
                "Feel free to ask your question in English or Malayalam-English (Manglish)!";
    }

    /**
     * Builds the system instruction for the AI model with complete MRBS context.
     */
    private String buildSystemPrompt(String user, String role, String userBookings) {
        StringBuilder sb = new StringBuilder();
        sb.append("You are the MRBS AI Assistant, an intelligent, polite, and helpful assistant for the Meeting Room Booking System (MeetRoom Pro).\n");
        sb.append("Current Session User: ").append(user).append(" (Role: ").append(role).append(").\n\n");
        sb.append("Application Knowledge & Rules:\n");
        sb.append("- Application: Pure Java Servlets + JSP + MySQL Meeting Room Booking System.\n");
        sb.append("- Navigation:\n");
        sb.append("  • Dashboard: /dashboard.jsp\n");
        sb.append("  • Book a Room: /bookings\n");
        sb.append("  • Room Availability: /availability\n");
        sb.append("  • Room Management (Admin): /rooms\n");
        sb.append("  • Booking History & Invoices: /history\n");
        sb.append("  • Login: / or /login\n");
        sb.append("- Student Perks: All students and student clubs receive a 20% discount subsidy automatically.\n");
        sb.append("- Schedule Conflict Prevention: Zero double-booking guarantee. Rooms cannot overlap on the same date and time.\n");
        sb.append("- Payments: Online UPI QR (GPay/PhonePe/Paytm) and 3 Offline campus counters.\n");
        sb.append("- Rooms:\n");
        sb.append("  • CR-101 Apollo Conference Hall (20 cap, $25/hr, student $20/hr, 4K Projector, Wi-Fi)\n");
        sb.append("  • MR-202 Boardroom Executive (12 cap, $30/hr, student $24/hr, Smart TV, Wi-Fi)\n");
        sb.append("  • HR-301 Innovation Student Huddle (6 cap, $10/hr, student $8/hr, Wall Display, Wi-Fi)\n");
        sb.append("  • CR-105 Orion Auditorium (30 cap, $40/hr, student $32/hr, Dual Projectors, Sound)\n");
        sb.append("  • MR-404 Genesis Collaboration (10 cap, $15/hr, student $12/hr, Video Bar, Wi-Fi)\n");

        if (userBookings != null && !userBookings.isEmpty()) {
            sb.append("\nCurrent Authenticated User's Real Reservations:\n").append(userBookings).append("\n");
        }

        sb.append("\nInstructions:\n");
        sb.append("1. Answer concisely, accurately, and politely.\n");
        sb.append("2. Answer in English by default. If the user asks in Malayalam-English (Manglish), reply in helpful, friendly Manglish/English.\n");
        sb.append("3. Direct users to the exact application pages when instructing them.\n");
        sb.append("4. Never invent fake reservations or expose another user's personal data.\n");
        sb.append("5. Also answer general academic and computer science questions accurately.");

        return sb.toString();
    }

    /**
     * Safely queries the database for the active user's bookings only.
     */
    private String fetchUserBookingsSummary(String user, String role) {
        StringBuilder sb = new StringBuilder();
        String sql;
        if ("Admin".equalsIgnoreCase(role)) {
            sql = "SELECT booking_number, room_name, room_number, meeting_title, meeting_date, start_time, end_time, booking_status " +
                    "FROM bookings WHERE booking_status = 'Booked' ORDER BY meeting_date ASC LIMIT 5";
        } else {
            sql = "SELECT booking_number, room_name, room_number, meeting_title, meeting_date, start_time, end_time, booking_status " +
                    "FROM bookings WHERE (employee_name LIKE ? OR user_type = 'Student') AND booking_status = 'Booked' ORDER BY meeting_date ASC LIMIT 5";
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (!"Admin".equalsIgnoreCase(role)) {
                ps.setString(1, "%" + user + "%");
            }

            try (ResultSet rs = ps.executeQuery()) {
                int count = 0;
                while (rs.next()) {
                    count++;
                    sb.append(String.format("• #%s: %s (%s) on %s from %s to %s [Status: %s]\n",
                            rs.getString("booking_number"),
                            rs.getString("room_name"),
                            rs.getString("room_number"),
                            rs.getString("meeting_date"),
                            rs.getString("start_time").substring(0, 5),
                            rs.getString("end_time").substring(0, 5),
                            rs.getString("booking_status")));
                }
                if (count == 0) return null;
            }
        } catch (Exception e) {
            System.err.println("[ChatServlet] Note: Could not query user bookings: " + e.getMessage());
        }
        return sb.length() > 0 ? sb.toString() : null;
    }

    private String extractMessage(HttpServletRequest request) throws IOException {
        String contentType = request.getContentType();
        if (contentType != null && contentType.toLowerCase().contains("application/json")) {
            StringBuilder sb = new StringBuilder();
            try (BufferedReader reader = request.getReader()) {
                String line;
                while ((line = reader.readLine()) != null) {
                    sb.append(line);
                }
            }
            String rawJson = sb.toString();
            String msg = parseFieldFromJson(rawJson, "message");
            if (msg == null) msg = parseFieldFromJson(rawJson, "prompt");
            if (msg == null) msg = parseFieldFromJson(rawJson, "content");
            return msg;
        } else {
            String msg = request.getParameter("message");
            if (msg == null) msg = request.getParameter("prompt");
            if (msg == null) msg = request.getParameter("content");
            return msg;
        }
    }

    private String parseGeminiReply(String json) {
        if (json == null) return null;
        try {
            int keyIdx = json.indexOf("\"text\"");
            if (keyIdx != -1) {
                int colonIdx = json.indexOf(':', keyIdx);
                if (colonIdx != -1) {
                    int quoteStart = json.indexOf('"', colonIdx);
                    if (quoteStart != -1) {
                        return extractJsonStringContent(json, quoteStart + 1);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("[ChatServlet] parseGeminiReply error: " + e.getMessage());
        }
        return null;
    }

    private String parseOpenAIReply(String json) {
        if (json == null) return null;
        try {
            int keyIdx = json.indexOf("\"content\"");
            if (keyIdx != -1) {
                int colonIdx = json.indexOf(':', keyIdx);
                if (colonIdx != -1) {
                    int quoteStart = json.indexOf('"', colonIdx);
                    if (quoteStart != -1) {
                        return extractJsonStringContent(json, quoteStart + 1);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("[ChatServlet] parseOpenAIReply error: " + e.getMessage());
        }
        return null;
    }

    private String parseFieldFromJson(String json, String field) {
        if (json == null || field == null) return null;
        int keyIdx = json.indexOf("\"" + field + "\"");
        if (keyIdx == -1) return null;
        int colonIdx = json.indexOf(':', keyIdx);
        if (colonIdx == -1) return null;
        int quoteStart = json.indexOf('"', colonIdx);
        if (quoteStart == -1) return null;
        return extractJsonStringContent(json, quoteStart + 1);
    }

    private String extractJsonStringContent(String json, int start) {
        StringBuilder sb = new StringBuilder();
        boolean escape = false;
        for (int i = start; i < json.length(); i++) {
            char c = json.charAt(i);
            if (escape) {
                switch (c) {
                    case 'n': sb.append('\n'); break;
                    case 'r': sb.append('\r'); break;
                    case 't': sb.append('\t'); break;
                    case '"': sb.append('"'); break;
                    case '\\': sb.append('\\'); break;
                    case 'b': sb.append('\b'); break;
                    case 'f': sb.append('\f'); break;
                    case 'u':
                        if (i + 4 < json.length()) {
                            try {
                                String hex = json.substring(i + 1, i + 5);
                                sb.append((char) Integer.parseInt(hex, 16));
                                i += 4;
                            } catch (Exception ex) {
                                sb.append('u');
                            }
                        }
                        break;
                    default:
                        sb.append(c);
                }
                escape = false;
            } else if (c == '\\') {
                escape = true;
            } else if (c == '"') {
                return sb.toString();
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    private void sendJsonResponse(HttpServletResponse response, int statusCode, boolean success, String reply, String provider) throws IOException {
        response.setStatus(statusCode);
        String escapedReply = escapeJsonString(reply);
        String json = String.format("{\"success\":%b,\"reply\":\"%s\",\"provider\":\"%s\"}",
                success, escapedReply, escapeJsonString(provider));
        response.getWriter().write(json);
    }

    private String escapeJsonString(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (c < ' ') {
                        String t = "000" + Integer.toHexString(c);
                        sb.append("\\u").append(t.substring(t.length() - 4));
                    } else {
                        sb.append(c);
                    }
            }
        }
        return sb.toString();
    }

    private String getEnvOrProp(String name, String defaultValue) {
        String val = System.getenv(name);
        if (val == null || val.trim().isEmpty()) {
            val = System.getProperty(name);
        }
        return (val != null && !val.trim().isEmpty()) ? val.trim() : defaultValue;
    }
}
