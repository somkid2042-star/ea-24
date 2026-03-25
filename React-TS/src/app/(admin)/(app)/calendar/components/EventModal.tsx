import { Calendar, type EventApi } from '@fullcalendar/core';
import React, { useState } from 'react';
import { LuX } from 'react-icons/lu';

type NewEventData = {
  date: Date;
  allDay: boolean;
};

type Props = {
  event: EventApi | null;
  newEventData: NewEventData | null;
  calendarObj: Calendar | null;
  onClose: () => void;
};

const EventModal: React.FC<Props> = ({ event, newEventData, calendarObj, onClose }) => {
  const [title, setTitle] = useState(event ? event.title : '');
  const [category, setCategory] = useState(event?.classNames?.[0] ?? '!text-primary');

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!calendarObj) return;

    if (event) {
      event.setProp('title', title);
      event.setProp('classNames', [category]);
    } else if (newEventData) {
      calendarObj.addEvent({
        title,
        start: newEventData.date,
        allDay: newEventData.allDay,
        className: category,
      });
    }
    onClose();
  };

  const handleDelete = () => {
    if (event) {
      event.remove();
    }
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 bg-black/40 flex justify-center items-center transition-all duration-200"
      role="dialog"
      aria-labelledby="event-modal-label"
    >
      <div className="w-full max-w-lg card w-full flex flex-col border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
        <div className="card-header flex justify-between items-center p-4">
          <h3
            id="event-modal-label"
            className="font-semibold text-base text-default-800 dark:text-white"
          >
            {event ? 'Edit Event' : 'Add Event'}
          </h3>
          <button
            type="button"
            className="text-default-800 hover:text-red-500"
            aria-label="Close"
            onClick={onClose}
          >
            <span className="sr-only">Close</span>
            <LuX className="size-5" />
          </button>
        </div>

        <form
          className="needs-validation"
          name="event-form"
          id="form-event"
          autoComplete="off"
          onSubmit={handleSubmit}
        >
          <div className="card-body p-4">
            <div className="grid grid-cols-1 gap-4">
              <div>
                <label htmlFor="event-title" className="inline-block mb-2 text-base font-medium">
                  Event Name
                </label>
                <input
                  type="text"
                  id="event-title"
                  className="form-input w-full"
                  placeholder="Event name"
                  required
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                />
              </div>

              <div>
                <label htmlFor="event-category" className="inline-block mb-2 text-base font-medium">
                  Category
                </label>
                <select
                  className="form-input flex items-center w-full"
                  name="event-category"
                  id="event-category"
                  required
                  value={category}
                  onChange={e => setCategory(e.target.value)}
                >
                  <option value="">Select Category</option>
                  <option value="!text-primary">Primary</option>
                  <option value="!text-success">Success</option>
                  <option value="!text-info">Info</option>
                  <option value="!text-warning">Warning</option>
                  <option value="!text-danger">Danger</option>
                </select>
              </div>
            </div>
          </div>

          <div className="card-footer flex gap-2 justify-end  p-4">
            <button
              type="button"
              onClick={onClose}
              className="bg-transparent text-danger btn border-0 hover:bg-red-50"
            >
              Cancel
            </button>

            {event && (
              <button
                type="button"
                onClick={handleDelete}
                id="btn-delete-event"
                className="bg-transparent text-danger btn border-0 hover:bg-red-50"
              >
                Delete
              </button>
            )}

            <button type="submit" id="btn-save-event" className="btn bg-primary text-white">
              {event ? 'Update Event' : 'Add Event'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EventModal;
