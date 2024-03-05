/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
window.MergeOrder = class MergeOrder {
  constructor($form) {
    this.$form = $form;
  }
    // empty body

  initTimeBasedServices() {
    if (!this.$form.length) { return; }

    this.$quantity_field = this.$form.find(".js--edit-order__quantity");
    this.$duration_display_field = this.$form.find(".js--edit-order__duration");

    // clockpunch converts the original field into a field with name _display.
    // We will need to disable both the visible display field and the hidden field
    // so they don't get sent as part of the POST unless a timed service is
    // selected.
    this.$duration_display_field.timeinput();
    this.$duration_hidden_field = this.$duration_display_field.data("timeparser").$hidden_field;

    this.$form.find(".js--edit-order__product").on("change", event => {
      const is_timed = $(event.target).find(":selected").data("timed-product");

      this.$duration_display_field.toggle(is_timed);
      this.$duration_display_field.prop("disabled", !is_timed);
      this.$duration_hidden_field.prop("disabled", !is_timed);

      if (is_timed) { this.$quantity_field.val(1); }
      return this.$quantity_field.prop("disabled", is_timed);
    });

    return this.$form.find(".js--edit-order__product").trigger("change");
  }
};

$(function() {
  const mergeOrder = new MergeOrder($(".js--edit-order"));
  mergeOrder.initTimeBasedServices();
});
