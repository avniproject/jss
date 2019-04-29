import {
    FormElementRule,
    FormElementsStatusHelper,
    StatusBuilderAnnotationFactory,
    FormElementStatusBuilder,
    FormElementStatus,
} from 'rules-config/rules';
import {WithName} from "rules-config";
import moment from 'moment';
import _ from 'lodash';

const WithStatusBuilder = StatusBuilderAnnotationFactory('programEncounter', 'formElement');

@FormElementRule({
    name: 'JSS Growth Monitoring rules',
    uuid: 'e6c03ec8-fb2d-40e4-a0a0-50fb3c91c53e',
    formUUID: 'd062907a-690c-44ca-b699-f8b2f688b075',
    executionOrder: 100.0,
    metadata: {}
})

class ShowHeightHandler {
    static exec(encounter, formElementGroup, today) {
        return FormElementsStatusHelper
            .getFormElementsStatusesWithoutDefaults(new ShowHeightHandler(), encounter, formElementGroup, today);
    }

    @WithName("Height")
    one(programEncounter, formElement) {
        if (!_.isNil(programEncounter.earliestVisitDateTime)) {
            const lastEncounterWithHeight = programEncounter.programEnrolment.findLatestPreviousEncounterWithObservationForConcept(programEncounter, "Height");
            const heightNeverCapturedBefore = _.isNil(lastEncounterWithHeight);
            const ageInMonths = programEncounter.programEnrolment.individual.getAgeInMonths(programEncounter.earliestVisitDateTime, false);
            const ageInMonthMultipleOf6 = ((ageInMonths % 6) === 0);
            const endDate = programEncounter.earliestVisitDateTime;
            const startDate = moment(programEncounter.earliestVisitDateTime).subtract((ageInMonths % 6), 'months').startOf('month').toDate();
            const encBetweenDatesWithHeight = _.chain(programEncounter.programEnrolment.encounters)
                .filter((enc) => (enc.encounterDateTime <= endDate && enc.encounterDateTime >= startDate)
                    && !_.isNil(enc.findObservation("Height")));
            const heightToBeCapturedThisTime = (heightNeverCapturedBefore || (ageInMonthMultipleOf6 && encBetweenDatesWithHeight.value().length === 0) || encBetweenDatesWithHeight.value().length === 0);
            return new FormElementStatus(formElement.uuid, heightToBeCapturedThisTime);
        } else {
            let skipCaptureHeightNotDefinedBuilder = new FormElementStatusBuilder({programEncounter, formElement});
            skipCaptureHeightNotDefinedBuilder.show().valueInEncounter("Skip capturing height").is.notDefined;
            let skipCaptureHeightNotYesBuilder = new FormElementStatusBuilder({programEncounter, formElement});
            skipCaptureHeightNotYesBuilder.show().not.valueInEncounter("Skip capturing height").is.yes;
            return new FormElementStatus(formElement.uuid, (skipCaptureHeightNotDefinedBuilder.build().visibility || skipCaptureHeightNotYesBuilder.build().visibility));
        }
    }

    @WithName("Skip capturing height")
    @WithStatusBuilder
    two([encounter], statusBuilder) {
        if (!_.isNil(encounter.earliestVisitDateTime)) {
            const monthsDiff = moment().diff(encounter.programEnrolment.individual.dateOfBirth, 'months');
            statusBuilder.show().whenItem(1 === 2).is.truthy;
        }
    }
}

module.exports = {ShowHeightHandler};
