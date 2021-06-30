import {AlbendazoleVisitScheduleJSS} from "../../child/rules/albendazoleTrackingHandler";
import {RuleFactory, VisitScheduleBuilder} from "rules-config";

const postVisitMap = {
    'Anthropometry Assessment': GMCancelVisitScheduleJSS,
    'Albendazole': AlbendazoleVisitScheduleJSS
};
const CancelVisitSchedules = RuleFactory("aac5c57a-aa01-49bb-ad20-70536dd2907f", "VisitSchedule");

class GMCancelVisitScheduleJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        const myGroups = programEncounter.programEnrolment.individual.groups;
        //not scheduling next visit when recording unplanned visit or if child is not a part of phulwari group
        if(!programEncounter.programEnrolment.isActive || _.isEmpty(myGroups)){
            return [];
        }
        const groupSubject = _.get(_.find(myGroups, g => !g.voided && g.groupSubject.subjectType.name === 'Phulwari'), 'groupSubject');
        const scheduleBuilder = new VisitScheduleBuilder({
            programEnrolment: programEncounter.programEnrolment
        });
        const scheduledDateTime = programEncounter.earliestVisitDateTime;
        const scheduledDate = moment(scheduledDateTime).date();
        const dayOfMonth = groupSubject.getObservationReadableValue("Day of month for growth monitoring visit");
        const monthForNextVisit = scheduledDate < dayOfMonth ? moment(scheduledDateTime).month() : moment(scheduledDateTime).month() + 1;
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

@CancelVisitSchedules("f58963fe-87d5-4344-ad5e-9770f89d60cf", "JSS Growth Monitoring Next Visit", 100.0)
class CancelVisitSchedulesJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        let visitCancelReason = programEncounter.findCancelEncounterObservationReadableValue('Visit cancel reason');
        if (visitCancelReason === 'Program exit') {
            return visitSchedule;
        }
        let postVisit = postVisitMap[programEncounter.encounterType.name];
        if (!_.isNil(postVisit)) {
            return postVisit.exec(programEncounter, visitSchedule);
        }
        return visitSchedule;
    }
}

export {
    CancelVisitSchedulesJSS
}
