const rulesConfigInfra = require('rules-config/infra');
const IDI = require('openchs-idi');
const secrets = require('../secrets.json');

module.exports = IDI.configure({
    "name": "jss",
    "chs-admin": "admin",
    "org-name": "JSS",
    "org-admin": "adminjss",
    "secrets": secrets,
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
        "catchments": ["./catchments/sample.json"],
        "checklistDetails": [],
        "concepts": [
            "./concepts.json",
            "./registrationConcepts.json",
            "./child/enrolmentConcepts.json",
        ],
        "locations": [
            "./locations/sample.json",
        ],
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
        ]
    }
}, rulesConfigInfra);
