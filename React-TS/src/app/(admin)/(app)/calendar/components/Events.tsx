import { forwardRef } from 'react';
import { TbCircleFilled } from 'react-icons/tb';

const ExternalEvents = forwardRef<HTMLDivElement>((_, ref) => {
  return (
    <div id="external-events" ref={ref} className="flex flex-col gap-3">
      <p className="text-default-400">Drag and drop your event or click in the calendar</p>

      <div className="external-event fc-event text-success" data-class="!text-success">
        <TbCircleFilled className="inline-block me-2" /> New Event Planning
      </div>

      <div className="external-event fc-event text-info" data-class="!text-info">
        <TbCircleFilled className="inline-block me-2" /> Meeting
      </div>

      <div className="external-event fc-event text-warning" data-class="!text-warning">
        <TbCircleFilled className="inline-block me-2" /> Generating Reports
      </div>

      <div className="external-event fc-event text-danger" data-class="!text-danger">
        <TbCircleFilled className="inline-block me-2" /> Create New theme
      </div>

      <div className="flex items-center gap-2">
        <input id="drop-remove" className="form-checkbox" type="checkbox" />
        <label htmlFor="drop-remove" className="align-middle cursor-pointer">
          Remove after drop
        </label>
      </div>

      <div className="flex items-center gap-2">
        <input id="businessCalendar" className="form-checkbox" type="checkbox" />
        <label htmlFor="businessCalendar" className="align-middle cursor-pointer">
          Business Hours & Week
        </label>
      </div>

      <div className="flex items-center gap-2">
        <input id="weekNumberCalendar" className="form-checkbox" type="checkbox" />
        <label htmlFor="weekNumberCalendar" className="align-middle cursor-pointer">
          Week Number
        </label>
      </div>
    </div>
  );
});

ExternalEvents.displayName = 'ExternalEvents';
export default ExternalEvents;
