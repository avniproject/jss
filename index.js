const {postAllRules} = require("rules-config/infra");
const _ = require('lodash');
const serverurl = _.isEmpty(process.argv[2]) ? 'http://localhost:8021' : process.argv[2];
const token = _.isEmpty(process.argv[3]) ? '' : process.argv[3];
const orgAdmin = _.isEmpty(process.argv[4]) ? '' : process.argv[4];
postAllRules(orgAdmin, "./rules.js", serverurl, token);
