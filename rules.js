const moment = require("moment");
const _ = require("lodash");
import {
    RuleFactory,
    FormElementsStatusHelper,
    FormElementStatusBuilder,
    FormElementStatus,
    VisitScheduleBuilder
} from 'rules-config/rules';

const RegistrationViewFilter = RuleFactory("e0b78ca2-1205-4e84-9f9b-d97c9b78a917", "ViewFilter");
const EnrolmentViewFilter = RuleFactory("1608c2c0-0334-41a6-aab0-5c61ea1eb069", "ViewFilter");
const EnrolmentVisitSchedule = RuleFactory("1608c2c0-0334-41a6-aab0-5c61ea1eb069", "VisitSchedule");
const AnthropometryViewFilter = RuleFactory("d062907a-690c-44ca-b699-f8b2f688b075", "ViewFilter");


const gmpVisit = (programEnrolment, visitSchedule, currentDateTime = new Date()) => {
    const scheduleBuilder = new VisitScheduleBuilder({
        programEnrolment: programEnrolment
    });
    const encounterDateTime = currentDateTime;
    visitSchedule.forEach((vs) => scheduleBuilder.add(vs));
    scheduleBuilder.add({
            name: "Growth Monitoring Visit",
            encounterType: "Anthropometry Assessment",
            earliestDate: encounterDateTime,
            maxDate: encounterDateTime
        }
    );
    return scheduleBuilder.getAllUnique("encounterType");
};

@EnrolmentVisitSchedule("4603fabd-b1f0-4106-9673-2ce397cbdf2c", "JSS Growth Monitoring Visit Schedule", 100.0)
class EnrolmentVisitScheduleJSS {
    static exec(programEnrolment, visitSchedule = [], scheduleConfig) {
        return gmpVisit(programEnrolment, visitSchedule, programEnrolment.enrolmentDateTime);
    }
}

@RegistrationViewFilter("c2e89483-4bdd-4d39-adf3-88a69579d07d", "JSS Registration View Filter", 1.0, {})
class RegistrationHandlerJSS {
    static exec(individual, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatuses(new RegistrationHandlerJSS(), individual, formElementGroup);
    }

    economicStatus(individual, formElement) {
        const statusBuilder = this._getStatusBuilder(individual, formElement);
        statusBuilder.skipAnswers("Antyodaya").whenItem(true).is.truthy;
        return statusBuilder.build();
    }

    _getStatusBuilder(individual, formElement) {
        return new FormElementStatusBuilder({individual, formElement});
    }
}


@EnrolmentViewFilter("520bf19c-cce8-4db5-8ab8-1b8ad57d0b75", "JSS Child Enrolment View Filter", 10.0)
class ChildEnrolmentHandlerJSS {
    static exec(programEnrolment, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new ChildEnrolmentHandlerJSS(), programEnrolment, formElementGroup);
    }

    pleaseSelectTheDisabilities(programEnrolment, formElement) {
        const statusBuilder = this._getStatusBuilder(programEnrolment, formElement);
        statusBuilder.show().when.valueInEntireEnrolment("Is there any developmental delay or disability seen?")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    chronicIllness(programEnrolment, formElement) {
        const statusBuilder = this._getStatusBuilder(programEnrolment, formElement);
        statusBuilder.show().when.valueInEntireEnrolment("Chronic Illness")
            .containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    _getStatusBuilder(programEnrolment, formElement) {
        return new FormElementStatusBuilder({programEnrolment, formElement});
    }
}


@AnthropometryViewFilter("ecccd36f-66d8-4e2a-bde1-48be86c3ba20", "Don't capture height for 6 months", 1000.0, {})
class AnthropometryHandlerJSS {
    height(programEncounter, formElement) {
        const lastEncounterWithHeight = programEncounter.programEnrolment.findLatestPreviousEncounterWithObservationForConcept(programEncounter, "Height");
        const lastCapturedHeightDate = _.get(lastEncounterWithHeight, "encounterDateTime", moment(new Date()).subtract(7, 'months').toDate());
        const diff = moment(_.defaults(programEncounter.encounterDateTime, new Date()))
            .diff(moment(lastCapturedHeightDate), 'months', true);
        return new FormElementStatus(formElement.uuid, diff > 5);
    }

    static exec(programEncounter, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatuses(new AnthropometryHandlerJSS(), programEncounter, formElementGroup);
    }
}

module.exports =
    {RegistrationHandlerJSS, ChildEnrolmentHandlerJSS, AnthropometryHandlerJSS, EnrolmentVisitScheduleJSS};