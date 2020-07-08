import { action } from "@ember/object";
import FolderValidations from "../validations/folder";
import lookupValidator from "ember-changeset-validations";
import Changeset from "ember-changeset";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import BaseFormComponent from "./base-form-component";
import { isPresent } from "@ember/utils";

export default class FolderForm extends BaseFormComponent {
  @service store;
  @service router;

  @tracked selectedTeam;
  @tracked assignableTeams;

  FolderValidations = FolderValidations;

  constructor() {
    super(...arguments);

    this.record = this.args.folder || this.store.createRecord("folder");

    this.isNewRecord = this.record.isNew;

    this.changeset = new Changeset(
      this.record,
      lookupValidator(FolderValidations),
      FolderValidations
    );

    if (this.isNewRecord && isPresent(this.args.team)) {
      this.changeset.team = this.args.team;
    }

    this.store.findAll("team").then(teams => {
      this.assignableTeams = teams;
      if (isPresent(this.changeset.team)) {
        this.selectedTeam = teams.find(
          team => team.id === this.changeset.get("team.id")
        );
      }
    });
  }

  @action
  abort() {
    if (this.args.onAbort) {
      this.args.onAbort();
      return;
    }
  }

  @action
  setSelectedTeam(selectedTeam) {
    this.selectedTeam = selectedTeam;
    this.changeset.team = selectedTeam;
  }

  async beforeSubmit() {
    await this.changeset.validate();
    return this.changeset.isValid;
  }

  handleSubmitSuccess(savedRecords) {
    this.abort();
    if (this.isNewRecord) {
      this.router.transitionTo(
        "/teams?team_id=" +
          savedRecords[0].team.get("id") +
          "&folder_id=" +
          savedRecords[0].id
      );
    }
  }
}
