/**
 * MEETING ROOM BOOKING SYSTEM - CLIENT SCRIPTS
 */

document.addEventListener('DOMContentLoaded', function () {
    // 1. Auto-dismiss alerts after 5 seconds
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

    // 3. Booking form time validation
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

function updateRoomCapacityNotice(selectElement) {
    const noticeEl = document.getElementById('roomCapacityNotice');
    if (!noticeEl) return;
    const selectedOption = selectElement.options[selectElement.selectedIndex];
    if (selectedOption && selectedOption.value) {
        const capacity = selectedOption.getAttribute('data-capacity') || 'N/A';
        const type = selectedOption.getAttribute('data-type') || 'Meeting Room';
        noticeEl.innerHTML = `<i class="bi bi-info-circle me-1"></i> Room Type: <strong>${type}</strong> | Max Capacity: <strong>${capacity} people</strong>`;
        noticeEl.classList.remove('d-none');
    } else {
        noticeEl.classList.add('d-none');
    }
}

/**
 * Pre-populate Room Edit Modal
 */
function openEditRoomModal(id, number, name, building, floor, capacity, type, facilities, status) {
    document.getElementById('editRoomId').value = id;
    document.getElementById('editRoomNumber').value = number;
    document.getElementById('editRoomName').value = name;
    document.getElementById('editBuilding').value = building;
    document.getElementById('editFloor').value = floor;
    document.getElementById('editCapacity').value = capacity;
    document.getElementById('editRoomType').value = type;
    document.getElementById('editFacilities').value = facilities;
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

/**
 * Client-side TXT receipt generator & downloader
 */
function downloadReceiptTxt(bookingNumber, title, date, timeSlot, roomName, roomNumber, empName, empId, dept, participants, purpose) {
    const content = 
`================================================================================
                     MEETING ROOM BOOKING SYSTEM - RECEIPT                      
================================================================================
Booking Reference : ${bookingNumber}
Date of Booking   : ${date}
Time Slot         : ${timeSlot}
--------------------------------------------------------------------------------
MEETING DETAILS
Title             : ${title}
Purpose           : ${purpose || 'N/A'}
Participants      : ${participants} persons
--------------------------------------------------------------------------------
ROOM INFORMATION
Room Name         : ${roomName}
Room Number       : ${roomNumber}
--------------------------------------------------------------------------------
BOOKED BY
Employee Name     : ${empName}
Employee ID       : ${empId}
Department        : ${dept}
================================================================================
Generated on      : ${new Date().toLocaleString()}
Please present this confirmation slip when occupying the meeting room.
================================================================================`;

    const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `Receipt_${bookingNumber}.txt`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
