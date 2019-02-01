import moment from "moment";
import RuleHelper from "./RuleHelper";
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    VisitScheduleBuilder
} from 'rules-config/rules';

const FEB = 1;
const AUG = 7;
const VisitSchedule = RuleFactory("dc386316-a5fa-440d-88de-5cd49a1ddc1d", "VisitSchedule");

const findSlot = (anyDate) => {
    anyDate = moment(anyDate).startOf('day').toDate();
    if(moment(anyDate).month() < FEB) {
        return moment(anyDate).startOf('month').month(FEB).toDate();
    }
    if(moment(anyDate).month() === FEB) {
        return anyDate;
    }
    if(moment(anyDate).month() < AUG) {
        return moment(anyDate).startOf('month').month(AUG).toDate();
    }
    if(moment(anyDate).month() === AUG) {
        return anyDate;
    }
    return moment(anyDate).add(1, 'year').month(FEB).startOf('month').toDate();
};

const findNextSlot = (earliestDate) => {
    let guessedDate = startOfNextMonth(earliestDate);
    return findSlot(guessedDate);
};

const startOfNextMonth = (date) => {
    return moment(date).startOf('month').add(1,'months').startOf('day').toDate();
};

const getAlbendazoleVisitSchedule = (_earliestDate) => {
    let earliestDate = moment(_earliestDate).startOf('day').toDate();
    let maxDate = startOfNextMonth(earliestDate);
    if (moment(_earliestDate).month() === FEB) {
        return {
            name: 'Albendazole FEB',
            encounterType: 'Albendazole',
            earliestDate, maxDate,
        }
    }
    return {
        name: 'Albendazole AUG',
        encounterType: 'Albendazole',
        earliestDate, maxDate,
    }
};

@VisitSchedule('f40332d7-c880-43ef-8036-f5dc51c26426', 'JSS AlbendazoleVisitSchedule', 100.0, {})
class AlbendazoleVisitScheduleJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        let scheduleBuilder = RuleHelper.createProgramEncounterVisitScheduleBuilder(programEncounter, visitSchedule);
        RuleHelper.justSchedule(scheduleBuilder, getAlbendazoleVisitSchedule(findNextSlot(programEncounter.earliestVisitDateTime)));
        return scheduleBuilder.getAll();
    }
}

export {AlbendazoleVisitScheduleJSS, getAlbendazoleVisitSchedule, findSlot}