const rulesConfigInfra = require('rules-config/infra');
const IDI = require('openchs-idi');

module.exports = IDI.configure({
    "name": "jss",
    "chs-admin": "admin",
    "org-name": "JSS",
    "org-admin": "adminjss",
    "secrets": '../secrets.json',
    "files": {
        "adminUsers": {
            // "prod": [],
            "dev": ["./users/dev-admin-user.json"],
        },
        "forms": [
            "./child/albendazoleTrackingForm.json",
            "./registrationForm.json",
        ],
        "formMappings": ["./formMappings.json"],
        "formDeletions": [
            "./child/enrolmentDeletions.json",
        ],
        "formAdditions": [
            "./child/enrolmentAdditions.json",
        ],
        "catchments": {
            "dev": ["./catchments/sample.json"],
            "staging": ["./catchments/sample.json"],
        },
        "checklistDetails": [],
        "concepts": [
            "./concepts.json",
            "./registrationConcepts.json",
            "./child/enrolmentConcepts.json",
        ],
        "locations": {
            "dev": ["./locations/sample.json"],
            "staging": ["./locations/sample.json"],
            // "prod": ["./locations/tmp.json"],
        },
        "programs": [],
        "encounterTypes": ["./encounterTypes.json"],
        "operationalEncounterTypes": ["./operationalModules/operationalEncounterTypes.json"],
        "operationalPrograms": ["./operationalModules/operationalPrograms.json"],
        "operationalSubjectTypes": ["./operationalModules/operationalSubjectTypes.json"],
        "users": {
            "dev": ["./users/dev-users.json"]
        },
        "rules": [
            "./rules.js",
        ],
        "organisationSql": [
            /* "create_organisation.sql"*/
        ],
        "organisationConfig": ["organisationConfig.json"],
        "translations": [
            "translations/en.json",
            "translations/hi_IN.json",
        ]
    }
}, rulesConfigInfra);
