import moment from 'moment';

const FEB = 1;
const AUG = 7;

const startOfNextMonth = (date) => {
    return moment(date).startOf('month').add(1, 'months').startOf('day').toDate();
};

class albendazole {
    static findSlot(anyDate) {
        anyDate = moment(anyDate).startOf('day').toDate();
        if (moment(anyDate).month() < FEB) {
            return moment(anyDate).startOf('month').month(FEB).toDate();
        }
        if (moment(anyDate).month() === FEB) {
            return anyDate;
        }
        if (moment(anyDate).month() < AUG) {
            return moment(anyDate).startOf('month').month(AUG).toDate();
        }
        if (moment(anyDate).month() === AUG) {
            return anyDate;
        }
        return moment(anyDate).add(1, 'year').month(FEB).startOf('month').toDate();
    }

    static getVisitSchedule(_earliestDate) {
        let earliestDate = moment(_earliestDate).startOf('day').toDate();
        let maxDate = moment(earliestDate).endOf('month').toDate();
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
    }

    //it should simply be
    //return albendazole.findSlot(moment(currentVisitScheduledDate).add(6, 'months').startOf('month').toDate())
    //but need to test all scenarios
    static findNextSlot(currentVisitScheduledDate) {
        let guessedDate = startOfNextMonth(currentVisitScheduledDate);
        return albendazole.findSlot(guessedDate);
    }
}

export {
    albendazole
}