import { Calendar, type EventApi } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin, { type DateClickArg, Draggable } from '@fullcalendar/interaction';
import listPlugin from '@fullcalendar/list';
import timeGridPlugin from '@fullcalendar/timegrid';
import { useEffect, useRef, useState } from 'react';
import EventModal from './EventModal';
import ExternalEvents from './Events';

const CalendarApp = () => {
  const calendarRef = useRef<HTMLDivElement | null>(null);
  const externalEventsRef = useRef<HTMLDivElement | null>(null);
  const [calendarObj, setCalendarObj] = useState<Calendar | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<EventApi | null>(null);
  const [newEventData, setNewEventData] = useState<DateClickArg | null>(null);

  useEffect(() => {
    if (!calendarRef.current) return;

    if (externalEventsRef.current) {
      new Draggable(externalEventsRef.current, {
        itemSelector: '.external-event',
        eventData: eventEl => ({
          title: eventEl.innerText,
          classNames: eventEl.getAttribute('data-class')?.split(' ') || [],
        }),
      });
    }

    const calendar = new Calendar(calendarRef.current, {
      timeZone: 'local',
      editable: true,
      droppable: true,
      selectable: true,
      weekNumbers: false,
      initialView: 'dayGridMonth',
      themeSystem: 'standard',
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      headerToolbar: {
        left: 'prev,next,today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek,timeGridDay,listMonth',
      },
      // events: getDefaultEvents(),
      dateClick: info => {
        setShowModal(true);
        setSelectedEvent(null);
        setNewEventData(info);
      },
      eventClick: info => {
        setShowModal(true);
        setSelectedEvent(info.event);
        setNewEventData(null);
      },
      drop: info => {
        const checkbox = document.getElementById('drop-remove') as HTMLInputElement;
        if (checkbox?.checked) {
          info.draggedEl.parentNode?.removeChild(info.draggedEl);
        }
      },
    });

    calendar.render();
    setCalendarObj(calendar);

    return () => {
      calendar.destroy();
    };
  }, []);

  return (
    <>
      <div className="lg:col-span-3">
        <div className="card">
          <div className="card-body">
            <div ref={calendarRef} id="calendar"></div>
          </div>
        </div>
      </div>

      <div className="col-span-1 card">
        <div className="card-body">
          <h6 className="mb-4 text-15">Draggable Events</h6>
          <ExternalEvents ref={externalEventsRef} />
        </div>
      </div>

      {showModal && (
        <EventModal
          event={selectedEvent}
          newEventData={newEventData}
          calendarObj={calendarObj}
          onClose={() => setShowModal(false)}
        />
      )}
    </>
  );
};

export default CalendarApp;
