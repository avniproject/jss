import RuleHelper from "../../RuleHelper";
import {
    FormElementsStatusHelper,
    FormElementStatus,
    FormElementStatusBuilder,
    RuleFactory,
    VisitScheduleBuilder
} from 'rules-config/rules';
import {albendazole} from '../../shared/rules/visitSchedulingUtils';

const VisitSchedule = RuleFactory("dc386316-a5fa-440d-88de-5cd49a1ddc1d", "VisitSchedule");

@VisitSchedule('f40332d7-c880-43ef-8036-f5dc51c26426', 'JSS AlbendazoleVisitSchedule', 100.0, {})
class AlbendazoleVisitScheduleJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        let scheduleBuilder = RuleHelper.createProgramEncounterVisitScheduleBuilder(programEncounter, visitSchedule);
        RuleHelper.justSchedule(scheduleBuilder, albendazole.getVisitSchedule(albendazole.findNextSlot(programEncounter.earliestVisitDateTime)));
        return scheduleBuilder.getAll();
    }
}

export {AlbendazoleVisitScheduleJSS}