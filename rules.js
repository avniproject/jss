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
const GMVisitSchedule = RuleFactory("d062907a-690c-44ca-b699-f8b2f688b075", "VisitSchedule");
const GMCancelVisitSchedule = RuleFactory("aac5c57a-aa01-49bb-ad20-70536dd2907f", "VisitSchedule");
const AnthropometryViewFilter = RuleFactory("d062907a-690c-44ca-b699-f8b2f688b075", "ViewFilter");


@EnrolmentVisitSchedule("4603fabd-b1f0-4106-9673-2ce397cbdf2c", "JSS Growth Monitoring First Visit", 100.0)
class EnrolmentVisitScheduleJSS {
    static exec(programEnrolment, visitSchedule = [], scheduleConfig) {
        const scheduleBuilder = new VisitScheduleBuilder({
            programEnrolment: programEnrolment
        });
        const earliestDate = programEnrolment.enrolmentDateTime;
        const maxDate = programEnrolment.enrolmentDateTime;
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
        const maxDate = moment(encounterDateTime).month(monthForNextVisit).date(dayOfMonth).add(3, 'days').toDate();
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

@GMCancelVisitSchedule("f58963fe-87d5-4344-ad5e-9770f89d60cf", "JSS Growth Monitoring Next Visit", 100.0)
class GMCancelVisitScheduleJSS {
    static exec(programEncounter, visitSchedule = [], scheduleConfig) {
        if(!programEncounter.programEnrolment.isActive){
            return [];
        }
        const scheduleBuilder = new VisitScheduleBuilder({
            programEnrolment: programEncounter.programEnrolment
        });
        const scheduledDateTime = programEncounter.earliestVisitDateTime;
        const scheduledDate = moment(scheduledDateTime).date();
        const dayOfMonth = programEncounter.programEnrolment.findObservation("Day of month for growth monitoring visit").getValue();
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

@RegistrationViewFilter("c2e89483-4bdd-4d39-adf3-88a69579d07d", "JSS Registration View Filter", 1.0, {})
class RegistrationHandlerJSS {
    static exec(individual, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatuses(new RegistrationHandlerJSS(), individual, formElementGroup);
    }

    otherGramPanchayatPleaseSpecify(individual, formElement) {
        const statusBuilder = this._getStatusBuilder(individual, formElement);
        statusBuilder.show().when.valueInRegistration("Gram panchayat").containsAnswerConceptName("Other");
        return statusBuilder.build();
    }

    otherSubCastePleaseSpecify(individual, formElement) {
        const statusBuilder = this._getStatusBuilder(individual, formElement);
        statusBuilder.show().when.valueInRegistration("Sub Caste").containsAnswerConceptName("Other");
        return statusBuilder.build();
    }

    landArea(individual, formElement) {
        const statusBuilder = this._getStatusBuilder(individual, formElement);
        statusBuilder.show().when.valueInRegistration("Land possession").containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    otherPropertyPleaseSpecify(individual, formElement) {
        const statusBuilder = this._getStatusBuilder(individual, formElement);
        statusBuilder.show().when.valueInRegistration("Property").containsAnswerConceptName("Other");
        return statusBuilder.build();
    }

    _getStatusBuilder(individual, formElement) {
        return new FormElementStatusBuilder({individual, formElement});
    }
}

const VILLAGE_PHULWARI_MAPPING = new Map([["Payari", ["Payari"]],
    ["Sarai", ["Ramtola","Goratola"]],
    ["Tarang", ["Peepaltola"]],
    ["Katurdona", ["Katurdona"]],
    ["Khalebhanvar", ["Khalebhanvar"]],
    ["Khamroud Village", ["Baigantola","Panchayat Bhavan"]],
    ["Tankitola", ["Samudayik Bhavan"]],
    ["Chatua", ["Chatua", "Chatua 2"]],
    ["Piparha", ["Piparhatola"]],
    ["Tarera", ["Chhatenitola"]],
    ["Sital pani", ["Khodratola"]],
    ["Mithu mahua", ["Jarratola"]],
    ["Dona", ["Karhaitola"]],
    ["Daldali", ["Schooltola"]],
    ["Khumni", ["Old panchayat bhavan"]],
    ["BulhuPani", ["Tagritola"]],
    ["Dadra Silvari", ["Dadra Silvari"]],
    ["Neeche Silvari", ["Tikratola"]],
    ["Kodar Village", ["Tikratola"]],
    ["Khirni", ["Upartola"]],
    ["Tithi", ["Talvatola"]],
    ["Jaithari", ["Dongritola"]],
    ["Badi Tumi", ["Kharsolihantola"]],
    ["Kharsol", [""]],
    ["Chirpani", ["Schooltola"]],
    ["Dabhaniya", ["Schooltola"]],
    ["Majhauli", ["Majhuatola"]],
    ["Kui", [""]],
    ["Padmania Village", ["Pateratola"]],
    ["Gijri", ["Saraihatola"]],
    ["Amoda", ["Schooltola"]],
    ["Batiya", ["Batiya"]],
    ["Bijora", [""]],
    ["Thunguni", ["Mahuatola"]],
    ["Duradhar", ["Bhumiyatola"]],
    ["Khosurgod", [""]],
    ["Chottibairagi", [""]],
    ["Badibairagi", [""]],
    ["Alwar Village", [""]],
    ["Adwar", [""]],
    ["Lamsarai", [""]],
    ["Ghata", [""]],
    ["Hathbandha", [""]],
    ["Jairhi", [""]],
    ["Karoundi", [""]],
    ["Sarfa", ["Old anganwadi kendra"]],
    ["Ahirgawan", ["Panika"]]
]);


@EnrolmentViewFilter("520bf19c-cce8-4db5-8ab8-1b8ad57d0b75", "JSS Child Enrolment View Filter", 10.0)
class ChildEnrolmentHandlerJSS {
    static exec(programEnrolment, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new ChildEnrolmentHandlerJSS(), programEnrolment, formElementGroup);
    }

    pleaseSelectTheDisabilities(programEnrolment, formElement) {
        const statusBuilder = this._getStatusBuilder(programEnrolment, formElement);
        statusBuilder.show().when.valueInEnrolment("Is there any developmental delay or disability seen?").containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    chronicIllness(programEnrolment, formElement) {
        const statusBuilder = this._getStatusBuilder(programEnrolment, formElement);
        statusBuilder.show().when.valueInEnrolment("Chronic Illness").containsAnswerConceptName("Yes");
        return statusBuilder.build();
    }

    enrolTo(programEnrolment, formElement) {
        const statusBuilder = this._getStatusBuilder(programEnrolment, formElement);
        var villagePhulwariMappingClone = new Map(VILLAGE_PHULWARI_MAPPING);
        villagePhulwariMappingClone.delete(programEnrolment.individual.lowestAddressLevel.name);
        var flatten = _.flatten([...villagePhulwariMappingClone.values()]).filter((p)=>!_.isEmpty(p));
        statusBuilder.skipAnswers.apply(statusBuilder, flatten);
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
        const heightNeverCapturedBefore = _.isNil(lastEncounterWithHeight);
        const ageInMonths = programEncounter.programEnrolment.individual.getAgeInMonths(programEncounter.encounterDateTime, false);
        const ageInMonthMultipleOf6 = ((ageInMonths % 6) === 0);
        var heightToBeCapturedThisTime = (heightNeverCapturedBefore || ageInMonthMultipleOf6);
        return new FormElementStatus(formElement.uuid, heightToBeCapturedThisTime);
    }

    static exec(programEncounter, formElementGroup) {
        return FormElementsStatusHelper
            .getFormElementsStatuses(new AnthropometryHandlerJSS(), programEncounter, formElementGroup);
    }
}

module.exports =
    {RegistrationHandlerJSS, ChildEnrolmentHandlerJSS, AnthropometryHandlerJSS, EnrolmentVisitScheduleJSS, GMVisitScheduleJSS, GMCancelVisitScheduleJSS};