<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String chatUser = (String) session.getAttribute("user");
    String chatRole = (String) session.getAttribute("role");
    if (chatUser == null) chatUser = "Guest";
    if (chatRole == null) chatRole = "student".equalsIgnoreCase(chatUser) ? "Student" : ("admin".equalsIgnoreCase(chatUser) ? "Admin" : "Visitor");
%>
<!-- =========================================================
     MRBS AI CHATBOT ASSISTANT COMPONENT
     ========================================================= -->
<div id="mrbsChatContainer">
    <!-- Floating Launcher Button -->
    <button id="mrbsChatToggleBtn" type="button" class="btn btn-primary rounded-circle shadow-lg d-flex align-items-center justify-content-center" title="Chat with MRBS AI Assistant" aria-label="Open AI Assistant">
        <i class="bi bi-robot fs-3 text-white"></i>
        <span class="chat-badge-pulse"></span>
        <span class="chat-launcher-tooltip d-none d-md-inline">AI Assistant</span>
    </button>

    <!-- Chat Modal Window -->
    <div id="mrbsChatModal" class="card shadow-lg border-0" style="display: none;" role="dialog" aria-labelledby="chatTitle">
        <!-- Header -->
        <div class="card-header bg-primary text-white d-flex align-items-center justify-content-between py-3 px-3">
            <div class="d-flex align-items-center gap-2">
                <div class="position-relative">
                    <div class="bg-white bg-opacity-25 rounded-circle d-flex align-items-center justify-content-center" style="width: 38px; height: 38px;">
                        <i class="bi bi-robot fs-5 text-white"></i>
                    </div>
                    <span class="chat-status-dot"></span>
                </div>
                <div>
                    <h6 class="mb-0 fw-bold fs-6" id="chatTitle">MRBS AI Assistant</h6>
                    <div class="small text-white-50 d-flex align-items-center gap-1" style="font-size: 0.72rem;">
                        <span class="badge bg-light bg-opacity-25 text-white py-0 px-2 fw-semibold"><%= "Student".equalsIgnoreCase(chatRole) ? "🎓 Student Mode" : ("Admin".equalsIgnoreCase(chatRole) ? "🛡️ Admin Mode" : "Visitor") %></span>
                        <span>&bull; Online</span>
                    </div>
                </div>
            </div>
            <div class="d-flex align-items-center gap-1">
                <button type="button" class="btn btn-sm text-white p-1 hover-opacity" id="mrbsChatClearBtn" title="Clear Conversation" aria-label="Clear Chat">
                    <i class="bi bi-arrow-counterclockwise fs-5"></i>
                </button>
                <button type="button" class="btn btn-sm text-white p-1 hover-opacity" id="mrbsChatCloseBtn" title="Close Chat" aria-label="Close Chat">
                    <i class="bi bi-x-lg fs-5"></i>
                </button>
            </div>
        </div>

        <!-- Chat Stream (Scrollable) -->
        <div class="card-body p-3" id="mrbsChatBody">
            <div id="mrbsChatMessages" class="d-flex flex-column gap-3">
                <!-- Welcome Message Bubble -->
                <div class="chat-msg chat-msg-bot d-flex gap-2">
                    <div class="chat-avatar bg-primary text-white rounded-circle d-flex align-items-center justify-content-center flex-shrink-0">
                        <i class="bi bi-robot"></i>
                    </div>
                    <div class="chat-bubble-bot p-3 rounded-4 shadow-sm">
                        <div class="fw-semibold mb-1 small text-primary"><i class="bi bi-stars me-1"></i> MRBS Assistant</div>
                        <p class="mb-2 small">Hi! I'm your <strong>MRBS AI Assistant</strong>. How can I help you today?</p>
                        <div class="small text-muted mb-2" style="font-size: 0.75rem;">Here are a few quick topics:</div>
                        <div class="d-flex flex-wrap gap-1 chat-quick-chips">
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How do I get the 20% student discount?">🎓 20% Student Subsidy</button>
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How to book a meeting room?">📅 How to Book</button>
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How can I check available rooms?">🔍 Check Available Rooms</button>
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="Where can I see my booking history?">📑 Booking History</button>
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How do I cancel a booking?">🔄 Cancel a Booking</button>
                            <button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How can I contact the administrator?">📞 Contact Admin</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Typing Loading Indicator -->
            <div id="mrbsTypingIndicator" class="chat-msg chat-msg-bot gap-2 mt-2" style="display: none;">
                <div class="chat-avatar bg-primary text-white rounded-circle d-flex align-items-center justify-content-center flex-shrink-0">
                    <i class="bi bi-robot"></i>
                </div>
                <div class="chat-bubble-bot p-2 px-3 rounded-4 shadow-sm d-flex align-items-center gap-1">
                    <span class="typing-dot"></span>
                    <span class="typing-dot"></span>
                    <span class="typing-dot"></span>
                </div>
            </div>
        </div>

        <!-- Input Footer -->
        <div class="card-footer bg-light border-top p-2 px-3">
            <form id="mrbsChatForm" class="d-flex gap-2 align-items-center mb-1">
                <input type="text" id="mrbsChatInput" class="form-control form-control-sm rounded-pill px-3" placeholder="Ask MRBS Assistant anything..." maxlength="1000" autocomplete="off" required>
                <button type="submit" id="mrbsChatSendBtn" class="btn btn-primary rounded-circle d-flex align-items-center justify-content-center flex-shrink-0" style="width: 38px; height: 38px;" title="Send Message">
                    <i class="bi bi-send-fill fs-6"></i>
                </button>
            </form>
            <div class="d-flex justify-content-between align-items-center text-muted px-2" style="font-size: 0.68rem;">
                <span id="mrbsCharCount">0 / 1000</span>
                <span>Powered by MRBS AI &bull; English &amp; Manglish</span>
            </div>
        </div>
    </div>
</div>

<style>
/* Chatbot Floating Widget Styles */
#mrbsChatContainer {
    position: fixed;
    bottom: 24px;
    right: 24px;
    z-index: 1060;
    font-family: inherit;
}
#mrbsChatToggleBtn {
    width: 58px;
    height: 58px;
    background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
    border: none;
    box-shadow: 0 8px 24px rgba(37, 99, 235, 0.4) !important;
    position: relative;
    transition: transform 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
}
#mrbsChatToggleBtn:hover {
    transform: scale(1.08);
}
.chat-badge-pulse {
    position: absolute;
    top: 2px;
    right: 2px;
    width: 13px;
    height: 13px;
    border-radius: 50%;
    background-color: #10b981;
    border: 2px solid #ffffff;
    box-shadow: 0 0 0 rgba(16, 185, 129, 0.6);
    animation: chatPulse 2s infinite;
}
.chat-launcher-tooltip {
    position: absolute;
    right: 68px;
    background: #0f172a;
    color: #ffffff;
    padding: 5px 10px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    white-space: nowrap;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.2s ease;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}
#mrbsChatToggleBtn:hover .chat-launcher-tooltip {
    opacity: 1;
}
@keyframes chatPulse {
    0% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); }
    70% { box-shadow: 0 0 0 8px rgba(16, 185, 129, 0); }
    100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
}

/* Chat Modal Window */
#mrbsChatModal {
    position: absolute;
    bottom: 70px;
    right: 0;
    width: 380px;
    max-width: calc(100vw - 24px);
    height: 540px;
    max-height: calc(100dvh - 100px);
    border-radius: 16px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    box-shadow: 0 16px 40px rgba(15, 23, 42, 0.25) !important;
    background: #ffffff;
    border: 1px solid rgba(226, 232, 240, 0.8) !important;
    animation: chatSlideUp 0.25s ease-out;
}
[data-bs-theme="dark"] #mrbsChatModal {
    background: #0f172a;
    border-color: #1e293b !important;
}
@keyframes chatSlideUp {
    from { opacity: 0; transform: translateY(12px) scale(0.96); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}
.chat-status-dot {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background-color: #10b981;
    border: 2px solid #2563eb;
}
#mrbsChatBody {
    flex: 1 1 auto;
    overflow-y: auto;
    overflow-x: hidden;
    scroll-behavior: smooth;
    background: #f8fafc;
}
[data-bs-theme="dark"] #mrbsChatBody {
    background: #090d16;
}
.chat-avatar {
    width: 30px;
    height: 30px;
    font-size: 0.85rem;
}
.chat-bubble-bot {
    background: #ffffff;
    border: 1px solid #e2e8f0;
    color: #1e293b;
    max-width: 86%;
    word-break: break-word;
    overflow-wrap: anywhere;
    line-height: 1.45;
}
[data-bs-theme="dark"] .chat-bubble-bot {
    background: #1e293b;
    border-color: #334155;
    color: #f1f5f9;
}
.chat-bubble-user {
    background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
    color: #ffffff;
    max-width: 86%;
    word-break: break-word;
    overflow-wrap: anywhere;
    margin-left: auto;
    line-height: 1.45;
}
.chip-btn {
    font-size: 0.72rem;
    border-radius: 12px;
    text-align: left;
    white-space: normal;
}
.hover-opacity:hover {
    opacity: 0.8;
}
/* Typing Indicator */
.typing-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background-color: #94a3b8;
    display: inline-block;
    animation: typingBounce 1.4s infinite ease-in-out both;
}
.typing-dot:nth-child(1) { animation-delay: -0.32s; }
.typing-dot:nth-child(2) { animation-delay: -0.16s; }
@keyframes typingBounce {
    0%, 80%, 100% { transform: scale(0); }
    40% { transform: scale(1); }
}

/* Mobile & Split Screen Viewport Optimizations */
@media (max-width: 575.98px) {
    #mrbsChatContainer {
        bottom: 12px;
        right: 12px;
    }
    #mrbsChatToggleBtn {
        width: 50px;
        height: 50px;
    }
    #mrbsChatModal {
        width: calc(100vw - 24px);
        right: 0;
        bottom: 60px;
        height: calc(100dvh - 80px);
        max-height: calc(100dvh - 80px);
    }
}
</style>

<script>
(function() {
    const chatContainer = document.getElementById('mrbsChatContainer');
    const toggleBtn = document.getElementById('mrbsChatToggleBtn');
    const chatModal = document.getElementById('mrbsChatModal');
    const closeBtn = document.getElementById('mrbsChatCloseBtn');
    const clearBtn = document.getElementById('mrbsChatClearBtn');
    const chatForm = document.getElementById('mrbsChatForm');
    const chatInput = document.getElementById('mrbsChatInput');
    const sendBtn = document.getElementById('mrbsChatSendBtn');
    const messagesContainer = document.getElementById('mrbsChatMessages');
    const typingIndicator = document.getElementById('mrbsTypingIndicator');
    const charCount = document.getElementById('mrbsCharCount');
    const chatBody = document.getElementById('mrbsChatBody');

    const STORAGE_KEY = 'mrbs_chat_messages_v2';
    let isGenerating = false;
    let lastUserMessage = '';

    // Toggle Modal
    toggleBtn.addEventListener('click', () => {
        const isHidden = (chatModal.style.display === 'none' || chatModal.style.display === '');
        chatModal.style.display = isHidden ? 'flex' : 'none';
        if (isHidden) {
            chatInput.focus();
            scrollToBottom();
        }
    });

    closeBtn.addEventListener('click', () => {
        chatModal.style.display = 'none';
    });

    // Character Counter
    chatInput.addEventListener('input', () => {
        const len = chatInput.value.length;
        charCount.textContent = len + ' / 1000';
    });

    // Clear Chat
    clearBtn.addEventListener('click', () => {
        if (confirm('Clear current chat conversation?')) {
            localStorage.removeItem(STORAGE_KEY);
            // Reset to default welcome message
            messagesContainer.innerHTML = '';
            showDefaultWelcome();
        }
    });

    function showDefaultWelcome() {
        const welcomeDiv = document.createElement('div');
        welcomeDiv.className = 'chat-msg chat-msg-bot d-flex gap-2';
        welcomeDiv.innerHTML = '<div class="chat-avatar bg-primary text-white rounded-circle d-flex align-items-center justify-content-center flex-shrink-0">' +
            '<i class="bi bi-robot"></i></div>' +
            '<div class="chat-bubble-bot p-3 rounded-4 shadow-sm">' +
            '<div class="fw-semibold mb-1 small text-primary"><i class="bi bi-stars me-1"></i> MRBS Assistant</div>' +
            '<p class="mb-2 small">Hi! I\'m your <strong>MRBS AI Assistant</strong>. How can I help you today?</p>' +
            '<div class="small text-muted mb-2" style="font-size: 0.75rem;">Here are a few quick topics:</div>' +
            '<div class="d-flex flex-wrap gap-1 chat-quick-chips">' +
            '<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How do I get the 20% student discount?">🎓 20% Student Subsidy</button>' +
            '<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How to book a meeting room?">📅 How to Book</button>' +
            '<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How can I check available rooms?">🔍 Check Available Rooms</button>' +
            '<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="Where can I see my booking history?">📑 Booking History</button>' +
            '<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How do I cancel a booking?">🔄 Cancel a Booking</button>' +
            '<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 chip-btn" data-query="How can I contact the administrator?">📞 Contact Admin</button>' +
            '</div></div>';
        messagesContainer.appendChild(welcomeDiv);
        attachChipEvents();
    }

    // Quick Chip Buttons
    function attachChipEvents() {
        document.querySelectorAll('.chip-btn').forEach(btn => {
            btn.onclick = () => {
                const query = btn.getAttribute('data-query');
                if (query && !isGenerating) {
                    chatInput.value = query;
                    submitMessage(query);
                }
            };
        });
    }
    attachChipEvents();

    // Form Submit
    chatForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const text = chatInput.value.trim();
        if (!text || isGenerating) return;
        submitMessage(text);
    });

    async function submitMessage(text) {
        lastUserMessage = text;

        // Render User Message using DOM methods (safe from JSP EL interference)
        appendMessage('user', text);
        chatInput.value = '';
        charCount.textContent = '0 / 1000';
        setGenerating(true);

        try {
            // Dynamically resolve context path or fallback to relative URL
            const endpoint = (window.location.pathname.includes('/MRBS') || window.location.pathname.includes('/meetingroom'))
                ? '<%= request.getContextPath() %>/api/chat'
                : '/api/chat';

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ message: text })
            });

            const data = await response.json();
            if (data && data.reply && data.reply.trim().length > 0) {
                appendMessage('bot', data.reply);
            } else if (data && data.error) {
                appendErrorMessage(data.error);
            } else {
                appendErrorMessage('Sorry, I could not generate a response. Please try asking again.');
            }
        } catch (err) {
            console.error('Chat error:', err);
            appendErrorMessage('The AI assistant is temporarily unavailable. Please verify your connection or try again.');
        } finally {
            setGenerating(false);
            chatInput.focus();
        }
    }

    // DOM-based Message Appender (strictly avoids JSP template literal collisions)
    function appendMessage(sender, text) {
        if (!text || text.trim() === '') return;

        const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const msgDiv = document.createElement('div');
        msgDiv.className = 'chat-msg ' + (sender === 'user' ? 'chat-msg-user' : 'chat-msg-bot d-flex gap-2');

        const formattedHtml = formatChatMarkdown(text);

        if (sender === 'user') {
            const bubble = document.createElement('div');
            bubble.className = 'chat-bubble-user p-3 rounded-4 shadow-sm';

            const contentDiv = document.createElement('div');
            contentDiv.innerHTML = formattedHtml;

            const timeDiv = document.createElement('div');
            timeDiv.className = 'text-end text-white-50 mt-1';
            timeDiv.style.fontSize = '0.65rem';
            timeDiv.textContent = timeStr;

            bubble.appendChild(contentDiv);
            bubble.appendChild(timeDiv);
            msgDiv.appendChild(bubble);
        } else {
            const avatar = document.createElement('div');
            avatar.className = 'chat-avatar bg-primary text-white rounded-circle d-flex align-items-center justify-content-center flex-shrink-0';
            avatar.innerHTML = '<i class="bi bi-robot"></i>';

            const bubble = document.createElement('div');
            bubble.className = 'chat-bubble-bot p-3 rounded-4 shadow-sm';

            const header = document.createElement('div');
            header.className = 'fw-semibold mb-1 small text-primary';
            header.innerHTML = '<i class="bi bi-stars me-1"></i> MRBS Assistant';

            const contentDiv = document.createElement('div');
            contentDiv.innerHTML = formattedHtml;

            const timeDiv = document.createElement('div');
            timeDiv.className = 'text-end text-muted mt-1';
            timeDiv.style.fontSize = '0.65rem';
            timeDiv.textContent = timeStr;

            bubble.appendChild(header);
            bubble.appendChild(contentDiv);
            bubble.appendChild(timeDiv);

            msgDiv.appendChild(avatar);
            msgDiv.appendChild(bubble);
        }

        messagesContainer.appendChild(msgDiv);
        scrollToBottom();
        saveHistory();
    }

    function appendErrorMessage(errorText) {
        const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const msgDiv = document.createElement('div');
        msgDiv.className = 'chat-msg chat-msg-bot d-flex gap-2';

        const avatar = document.createElement('div');
        avatar.className = 'chat-avatar bg-danger text-white rounded-circle d-flex align-items-center justify-content-center flex-shrink-0';
        avatar.innerHTML = '<i class="bi bi-exclamation-triangle-fill"></i>';

        const bubble = document.createElement('div');
        bubble.className = 'chat-bubble-bot p-3 rounded-4 shadow-sm border-danger border-opacity-50';

        const header = document.createElement('div');
        header.className = 'fw-semibold mb-1 small text-danger';
        header.innerHTML = '<i class="bi bi-shield-exclamation me-1"></i> Assistant Notice';

        const contentDiv = document.createElement('div');
        contentDiv.textContent = errorText;

        const retryBtn = document.createElement('button');
        retryBtn.type = 'button';
        retryBtn.className = 'btn btn-sm btn-outline-danger py-0 px-2 mt-2';
        retryBtn.style.fontSize = '0.72rem';
        retryBtn.innerHTML = '<i class="bi bi-arrow-repeat me-1"></i> Retry Message';
        retryBtn.onclick = function() {
            if (lastUserMessage && !isGenerating) {
                submitMessage(lastUserMessage);
            }
        };

        const timeDiv = document.createElement('div');
        timeDiv.className = 'text-end text-muted mt-1';
        timeDiv.style.fontSize = '0.65rem';
        timeDiv.textContent = timeStr;

        bubble.appendChild(header);
        bubble.appendChild(contentDiv);
        if (lastUserMessage) bubble.appendChild(retryBtn);
        bubble.appendChild(timeDiv);

        msgDiv.appendChild(avatar);
        msgDiv.appendChild(bubble);

        messagesContainer.appendChild(msgDiv);
        scrollToBottom();
        saveHistory();
    }

    function setGenerating(state) {
        isGenerating = state;
        typingIndicator.style.display = state ? 'flex' : 'none';
        chatInput.disabled = state;
        sendBtn.disabled = state;
        if (state) scrollToBottom();
    }

    function scrollToBottom() {
        setTimeout(() => {
            chatBody.scrollTop = chatBody.scrollHeight;
        }, 30);
    }

    // Markdown Formatter (Bold, Links, Bullet Points, Code, Emojis)
    function formatChatMarkdown(text) {
        if (!text) return '';
        let escaped = text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');

        // Links [text](url)
        escaped = escaped.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="fw-semibold text-primary text-decoration-underline" target="_self">$1</a>');

        // Bold **text**
        escaped = escaped.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');

        // Italic *text*
        escaped = escaped.replace(/\*([^*]+)\*/g, '<em>$1</em>');

        // Code `text`
        escaped = escaped.replace(/`([^`]+)`/g, '<code class="badge bg-light text-dark font-monospace border">$1</code>');

        // Newlines to <br>
        escaped = escaped.replace(/\n/g, '<br>');

        return escaped;
    }

    // Local Storage History
    function saveHistory() {
        try {
            localStorage.setItem(STORAGE_KEY, messagesContainer.innerHTML);
        } catch (e) {}
    }

    function loadHistory() {
        try {
            const saved = localStorage.getItem(STORAGE_KEY);
            if (saved && saved.trim().length > 50) {
                messagesContainer.innerHTML = saved;
                attachChipEvents();
            }
        } catch (e) {}
    }

    loadHistory();
})();
</script>
