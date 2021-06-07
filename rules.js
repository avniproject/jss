import _ from 'lodash';

module.exports = _.merge({},
    // require('./registration/rules/registrationHandler'),
    // require('./shared/rules/cancelVisitsHandler'),
    require('./child/rules/enrolmentHandler'),
    // require('./child/rules/gmpHandler'),
    // require('./child/rules/albendazoleTrackingHandler'),
    // require('./child/rules/showHeightHandler'),
);
