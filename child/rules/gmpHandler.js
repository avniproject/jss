import {RuleFactory, VisitScheduleBuilder} from "rules-config";
import moment from 'moment';

const GMVisitSchedule = RuleFactory("d062907a-690c-44ca-b699-f8b2f688b075", "VisitSchedule");

@GMVisitSchedule("44160e78-23fc-46c1-8764-4c84a5847522", "JSS Growth Monitoring Recurring Visit", 100.0)
class GMVisitScheduleJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {

        //not scheduling next visit when recording unplanned visit
        if(_.isNil(programEncounter.earliestVisitDateTime)){
            return [];
        }

        const scheduleBuilder = new VisitScheduleBuilder({
            programEnrolment: programEncounter.programEnrolment
        });
        const scheduledDateTime = programEncounter.earliestVisitDateTime;
        const scheduledDate = moment(scheduledDateTime).date();
        const encounterDateTime = programEncounter.encounterDateTime;
        const dayOfMonth = programEncounter.programEnrolment.findObservation("Day of month for growth monitoring visit").getValue();
        var monthForNextVisit = moment(scheduledDateTime).month() + 1;
        if ((scheduledDate < dayOfMonth) //visit-with-enrolment scenario or 29/30 Feb scenario
            || moment(encounterDateTime).diff(scheduledDateTime, 'days') < -3)
        {
            monthForNextVisit = moment(scheduledDateTime).month();
        }
        const earliestDate = moment(scheduledDateTime).month(monthForNextVisit).date(dayOfMonth).toDate();
        const maxDate = moment(scheduledDateTime).month(monthForNextVisit).date(dayOfMonth).add(3, 'days').toDate();
        visitSchedule.forEach((vs) => scheduleBuilder.add(vs));
        scheduleBuilder.add({
                name: "Growth Monitoring Visit",
                encounterType: "Anthropometry Assessment",
                earliestDate: earliestDate,
                maxDate: maxDate
            }
        );
        return scheduleBuilder.getAllUnique("encounterType");

    }
}

export {
    GMVisitScheduleJSS
}