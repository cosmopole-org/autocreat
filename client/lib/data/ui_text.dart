// Centralized mock UI copy for every static label, helper text, tooltip,
// and message surfaced by the Flutter UI.
//
// This mock localization store intentionally contains a complete English and
// Persian (Farsi) version of every visible string used by the demo UI. The
// active language is selected by [languageProvider] at app startup/rebuild time.
import 'package:flutter/material.dart';

enum AppLanguage { english, persian }

extension AppLanguageX on AppLanguage {
  String get code => switch (this) {
        AppLanguage.english => 'en',
        AppLanguage.persian => 'fa',
      };

  Locale get locale => Locale(code);
  TextDirection get textDirection =>
      this == AppLanguage.persian ? TextDirection.rtl : TextDirection.ltr;
  String get nativeLabel => switch (this) {
        AppLanguage.english => 'English',
        AppLanguage.persian => 'فارسی',
      };
  String get shortLabel => switch (this) {
        AppLanguage.english => 'EN',
        AppLanguage.persian => 'فا',
      };

  static AppLanguage fromCode(String? code) =>
      code == 'fa' ? AppLanguage.persian : AppLanguage.english;
}

enum _UiTextKey {
  exception,
  autocreat,
  createYourAccount,
  startBuildingYourOrganizationalSystem,
  firstName,
  requiredText,
  lastName,
  emailAddress,
  emailIsRequired,
  invalidEmail,
  companyNameOptional,
  password,
  passwordIsRequired,
  atLeast8Characters,
  confirmPassword,
  passwordsDoNotMatch,
  createAccount,
  alreadyHaveAnAccount,
  signIn,
  demo123,
  demo,
  admin,
  welcomeBack,
  signInToYourOrganizationAccount,
  passwordTooShort,
  forgotPassword,
  signIn3,
  donTHaveAnAccount,
  createAccount3,
  demo3,
  tryDemoMode,
  noAccountNeededExploreWithSampleData,
  organizationalSystemBuilder,
  designComplexOrganizationalFlows,
  buildFormsAndDataModels,
  manageRolesAndPermissions,
  communicateViaTickets,
  flowSaved,
  editNodeLabel,
  label,
  cancel,
  save,
  canvasControls,
  zoomOut,
  zoomIn,
  fitScreen,
  autoLayout,
  flowEditor,
  unsaved,
  zoomOut3,
  zoomIn3,
  canvasControls3,
  saveFlow,
  addStartNode,
  addStepNode,
  addDecisionNode,
  addEndNode,
  fitToScreen,
  nodeProperties,
  deleteNode,
  close,
  startBuildingYourFlow,
  tapHereToAddAStartNodeNorUseTheToolbarOnTheLeft,
  newFlow,
  start,
  end,
  automationFlows,
  designReviewAndLaunchOrganizationalProcessFlowsWithClearStep,
  newText,
  searchFlows,
  noFlowsYet,
  createYourFirstOrganizationalFlow,
  createFlow,
  deleteFlow,
  thisWillDeleteTheFlowPermanently,
  totalFlows,
  active,
  draft,
  totalNodes,
  flowComplexity,
  nodesAndEdgesPerFlow,
  nodeTypes,
  openEditor,
  delete,
  nodeLabel,
  enterLabelEllipsis,
  description,
  optionalDescriptionEllipsis,
  assignedRole,
  errorLoadingRoles,
  noRoleAssigned,
  selectRoleEllipsis,
  assignedForm,
  errorLoadingForms,
  noFormAssigned,
  selectFormEllipsis,
  branches,
  addBranch,
  defaultText,
  conditionEGStatusApproved,
  position,
  capacity,
  members,
  flows,
  details,
  website,
  created,
  text,
  companies,
  organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK,
  newCompany,
  searchCompanies,
  noCompaniesYet,
  noResultsFound,
  createYourFirstCompanyToGetStarted,
  createCompany,
  deleteCompany,
  areYouSureYouWantToDeleteThisCompany,
  edit,
  editCompany,
  companyNameRequired,
  nameIsRequired,
  industry,
  formSaved,
  formEditor,
  fieldTypes,
  formName,
  clickAFieldTypeToAddIt,
  requiredText3,
  fieldProperties,
  placeholder,
  helpText,
  readOnly,
  hidden,
  options,
  add,
  newForm,
  formDefinitions,
  buildStructuredFormsThatCaptureReliableDataGuideUsersBeautif,
  searchForms,
  noFormsYet,
  createYourFirstFormDefinition,
  createForm,
  deleteForm,
  thisWillDeleteTheFormPermanently,
  totalForms,
  totalFields,
  fieldTypesDistribution,
  countOfEachFieldTypeAcrossAllForms,
  noFieldsDefined,
  userSaved,
  newUser,
  editUser,
  changePhoto,
  uploadPhoto,
  userInfo,
  firstNameRequired,
  lastNameRequired,
  emailRequired,
  phone,
  passwordRequired,
  newPasswordLeaveBlankToKeep,
  access,
  noRole,
  assignedRole3,
  activeAccount,
  inactiveUsersCannotLogIn,
  all,
  teamMembers,
  inviteTeammatesUnderstandAccountActivityAndBalanceRolesSoCol,
  addUser,
  searchMembers,
  noMembersFound,
  tryAdjustingYourSearchOrFilters,
  removeUser,
  removeThisUserFromTheSystem,
  totalMembers,
  admins,
  roleDistribution,
  membersByAssignedRole,
  statusOverview,
  accountActivity,
  inactive,
  remove,
  roleSaved,
  newRole,
  editRole,
  roleDetails,
  roleNameRequired,
  owner,
  manager,
  member,
  viewer,
  accessLevel,
  permissionCoverage,
  permissions,
  configureCrudPermissionsPerResource,
  resource,
  create,
  read,
  update,
  rolesPermissions,
  shapeSecureAccessPoliciesClarifyResponsibilitiesAndGiveEvery,
  searchRoles,
  noRolesYet,
  createRolesToManageAccessControl,
  createRole,
  deleteRole,
  deleteThisRolePermanently,
  totalRoles,
  permissionSets,
  membersPerRole,
  howManyUsersAreAssignedToEachRole,
  open,
  inProgress,
  resolved,
  closed,
  supportTickets,
  trackCustomerRequestsPrioritizeUrgentWorkAndKeepEveryResolut,
  newTicket,
  searchTickets,
  noTicketsFound,
  tryAdjustingYourFilters,
  total,
  low,
  med,
  high,
  urgent,
  priorityBreakdown,
  ticketsByPriorityLevel,
  statusDistribution,
  currentTicketStates,
  noData,
  dueToday,
  titleRequired,
  titleIsRequired,
  priority,
  attachment,
  ticketMessageSent,
  ticketid,
  noMessagesYet,
  attachFile,
  typeAMessage,
  ticketDetails,
  status,
  creator,
  assignee,
  dueDate,
  slaProgress,
  tags,
  deltacontent,
  templateSaved,
  templateName,
  attach,
  variables,
  addMore,
  startWritingYourLetterTemplate,
  availableVariables,
  useTheseVariablesInYourTemplateTheyWillBeReplacedWithActualV,
  userSFullName,
  userSEmail,
  companyName,
  currentDate,
  flowName,
  newLetterTemplate,
  uncategorized,
  letterTemplates,
  manageReusableLetterTemplatesWithDynamicVariablesReadyToSend,
  newTemplate,
  searchTemplates,
  noLetterTemplates,
  createReusableLetterTemplates,
  createTemplate,
  deleteTemplate,
  deleteThisLetterTemplatePermanently,
  totalTemplates,
  totalVariables,
  templatesByCategory,
  distributionAcrossCategories,
  allCategories,
  goodMorning,
  goodAfternoon,
  goodEvening,
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun,
  jan,
  feb,
  mar,
  apr,
  may,
  jun,
  jul,
  aug,
  sep,
  oct,
  nov,
  dec,
  hereSWhatSHappeningInYourOrganizationToday,
  activeOrganizations,
  activeFlows,
  automationPipelines,
  openTickets,
  needsAttention,
  closedTickets,
  activityOverview,
  ticketsFlowsLast7Days,
  tickets,
  ticketStatus,
  distributionOverview,
  noTicketsYet,
  recentTickets,
  latestActivity,
  viewAll,
  resolutionRate,
  slaCompliance,
  performanceMetrics,
  ticketKpisAtAGlance,
  quickActions,
  modelSaved,
  modelEditor,
  modelInfo,
  modelNameRequired,
  addField,
  noFieldsYetAddYourFirstField,
  jsonSchemaPreview,
  text3,
  unique,
  unique3,
  fieldNameRequired,
  fieldType,
  newModel,
  dataModels,
  defineDurableEntitySchemasOrganizeFieldsAndKeepYourOperation,
  searchModels,
  noModelsYet,
  defineYourDataStructures,
  createModel,
  deleteModel,
  deleteThisModelPermanently,
  totalModels,
  fieldTypeDistribution,
  breakdownOfFieldTypesAcrossAllModels,
  editLabel,
  deleteEdge,
  yes,
  no,
  form,
  role,
  y,
  n3,
  ellipsis,
  noNodes,
  dashboard,
  overview,
  organization,
  users,
  roles,
  automation,
  forms,
  models,
  letters,
  communication,
  menu,
  search,
  notifications,
  toggleTheme,
  search3,
  disableGlassMode,
  enableGlassMode,
  logout,
  signOut,
  select,
  selectDate,
  selectTime,
  clickToUploadFile,
  anyFileTypeSupported,
  clickToUploadImage,
  pngJpgGifSupported,
  pickAColor,
  done,
  signHere,
  column1,
  column2,
  column3,
  addRow,
  searchEllipsis,
  somethingWentWrong,
  retry,
  string,
  integer,
  float,
  boolean,
  date,
  dateTime,
  file,
  reference,
  textField,
  number,
  textArea,
  dropdown,
  multiSelect,
  checkbox,
  radioGroup,
  datePicker,
  timePicker,
  fileUpload,
  imageUpload,
  colorPicker,
  switchText,
  table,
  rating,
  signature,
  medium,
  there,
  emptyJsonObject,
  bulletSeparator,
  requiredAsterisk,
  schemaSeparator,
  step,
  decision,
  instances,
  approved,
  pending,
  rejected,
}

class UiText {
  const UiText._();

  static AppLanguage _language = AppLanguage.english;

  static AppLanguage get language => _language;
  static bool get isPersian => _language == AppLanguage.persian;
  static bool get isRtl => _language.textDirection == TextDirection.rtl;
  static Locale get locale => _language.locale;
  static TextDirection get textDirection => _language.textDirection;

  static void configureLanguage(AppLanguage language) {
    _language = language;
  }

  static String _text(_UiTextKey key) =>
      (_language == AppLanguage.persian ? _persian : _english)[key] ??
      _english[key] ??
      key.name;

  static const Map<_UiTextKey, String> _english = {
    _UiTextKey.exception: "Exception: ",
    _UiTextKey.autocreat: "AutoCreat",
    _UiTextKey.createYourAccount: "Create your account",
    _UiTextKey.startBuildingYourOrganizationalSystem:
        "Start building your organizational system",
    _UiTextKey.firstName: "First name",
    _UiTextKey.requiredText: "Required",
    _UiTextKey.lastName: "Last name",
    _UiTextKey.emailAddress: "Email address",
    _UiTextKey.emailIsRequired: "Email is required",
    _UiTextKey.invalidEmail: "Invalid email",
    _UiTextKey.companyNameOptional: "Company name (optional)",
    _UiTextKey.password: "Password",
    _UiTextKey.passwordIsRequired: "Password is required",
    _UiTextKey.atLeast8Characters: "At least 8 characters",
    _UiTextKey.confirmPassword: "Confirm password",
    _UiTextKey.passwordsDoNotMatch: "Passwords do not match",
    _UiTextKey.createAccount: "Create Account",
    _UiTextKey.alreadyHaveAnAccount: "Already have an account? ",
    _UiTextKey.signIn: "Sign in",
    _UiTextKey.demo123: "Demo123!",
    _UiTextKey.demo: "Demo",
    _UiTextKey.admin: "Admin",
    _UiTextKey.welcomeBack: "Welcome back",
    _UiTextKey.signInToYourOrganizationAccount:
        "Sign in to your organization account",
    _UiTextKey.passwordTooShort: "Password too short",
    _UiTextKey.forgotPassword: "Forgot password?",
    _UiTextKey.signIn3: "Sign In",
    _UiTextKey.donTHaveAnAccount: "Don't have an account? ",
    _UiTextKey.createAccount3: "Create account",
    _UiTextKey.demo3: "DEMO",
    _UiTextKey.tryDemoMode: "Try Demo Mode",
    _UiTextKey.noAccountNeededExploreWithSampleData:
        "No account needed — explore with sample data",
    _UiTextKey.organizationalSystemBuilder: "Organizational System Builder",
    _UiTextKey.designComplexOrganizationalFlows:
        "Design complex organizational flows",
    _UiTextKey.buildFormsAndDataModels: "Build forms and data models",
    _UiTextKey.manageRolesAndPermissions: "Manage roles and permissions",
    _UiTextKey.communicateViaTickets: "Communicate via tickets",
    _UiTextKey.flowSaved: "Flow saved",
    _UiTextKey.editNodeLabel: "Edit node label",
    _UiTextKey.label: "Label",
    _UiTextKey.cancel: "Cancel",
    _UiTextKey.save: "Save",
    _UiTextKey.canvasControls: "Canvas Controls",
    _UiTextKey.zoomOut: "Zoom Out",
    _UiTextKey.zoomIn: "Zoom In",
    _UiTextKey.fitScreen: "Fit Screen",
    _UiTextKey.autoLayout: "Auto Layout",
    _UiTextKey.flowEditor: "Flow Editor",
    _UiTextKey.unsaved: "Unsaved",
    _UiTextKey.zoomOut3: "Zoom out",
    _UiTextKey.zoomIn3: "Zoom in",
    _UiTextKey.canvasControls3: "Canvas controls",
    _UiTextKey.saveFlow: "Save Flow",
    _UiTextKey.addStartNode: "Add Start Node",
    _UiTextKey.addStepNode: "Add Step Node",
    _UiTextKey.addDecisionNode: "Add Decision Node",
    _UiTextKey.addEndNode: "Add End Node",
    _UiTextKey.fitToScreen: "Fit to screen",
    _UiTextKey.nodeProperties: "Node Properties",
    _UiTextKey.deleteNode: "Delete node",
    _UiTextKey.close: "Close",
    _UiTextKey.startBuildingYourFlow: "Start building your flow",
    _UiTextKey.tapHereToAddAStartNodeNorUseTheToolbarOnTheLeft:
        "Tap here to add a Start node,\nor use the toolbar on the left.",
    _UiTextKey.newFlow: "New Flow",
    _UiTextKey.start: "Start",
    _UiTextKey.end: "End",
    _UiTextKey.automationFlows: "Automation Flows",
    _UiTextKey.designReviewAndLaunchOrganizationalProcessFlowsWithClearStep:
        "Design, review, and launch organizational process flows with clear steps, connected decisions, and measurable outcomes.",
    _UiTextKey.newText: "New",
    _UiTextKey.searchFlows: "Search flows...",
    _UiTextKey.noFlowsYet: "No flows yet",
    _UiTextKey.createYourFirstOrganizationalFlow:
        "Create your first organizational flow",
    _UiTextKey.createFlow: "Create Flow",
    _UiTextKey.deleteFlow: "Delete Flow",
    _UiTextKey.thisWillDeleteTheFlowPermanently:
        "This will delete the flow permanently.",
    _UiTextKey.totalFlows: "Total Flows",
    _UiTextKey.active: "Active",
    _UiTextKey.draft: "Draft",
    _UiTextKey.totalNodes: "Total Nodes",
    _UiTextKey.flowComplexity: "Flow Complexity",
    _UiTextKey.nodesAndEdgesPerFlow: "Nodes and edges per flow",
    _UiTextKey.nodeTypes: "Node Types",
    _UiTextKey.openEditor: "Open Editor",
    _UiTextKey.delete: "Delete",
    _UiTextKey.nodeLabel: "Node Label",
    _UiTextKey.enterLabelEllipsis: "Enter label…",
    _UiTextKey.description: "Description",
    _UiTextKey.optionalDescriptionEllipsis: "Optional description…",
    _UiTextKey.assignedRole: "Assigned Role",
    _UiTextKey.errorLoadingRoles: "Error loading roles",
    _UiTextKey.noRoleAssigned: "No role assigned",
    _UiTextKey.selectRoleEllipsis: "Select role…",
    _UiTextKey.assignedForm: "Assigned Form",
    _UiTextKey.errorLoadingForms: "Error loading forms",
    _UiTextKey.noFormAssigned: "No form assigned",
    _UiTextKey.selectFormEllipsis: "Select form…",
    _UiTextKey.branches: "Branches",
    _UiTextKey.addBranch: "Add Branch",
    _UiTextKey.defaultText: "DEFAULT",
    _UiTextKey.conditionEGStatusApproved: "Condition (e.g. status == approved)",
    _UiTextKey.position: "Position",
    _UiTextKey.capacity: "Capacity",
    _UiTextKey.members: "Members",
    _UiTextKey.flows: "Flows",
    _UiTextKey.details: "Details",
    _UiTextKey.website: "Website",
    _UiTextKey.created: "Created",
    _UiTextKey.text: ".",
    _UiTextKey.companies: "Companies",
    _UiTextKey.organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK:
        "Organize client and partner workspaces, monitor portfolio health, and keep each organization easy to find and manage.",
    _UiTextKey.newCompany: "New Company",
    _UiTextKey.searchCompanies: "Search companies...",
    _UiTextKey.noCompaniesYet: "No companies yet",
    _UiTextKey.noResultsFound: "No results found",
    _UiTextKey.createYourFirstCompanyToGetStarted:
        "Create your first company to get started",
    _UiTextKey.createCompany: "Create Company",
    _UiTextKey.deleteCompany: "Delete Company",
    _UiTextKey.areYouSureYouWantToDeleteThisCompany:
        "Are you sure you want to delete this company?",
    _UiTextKey.edit: "Edit",
    _UiTextKey.editCompany: "Edit Company",
    _UiTextKey.companyNameRequired: "Company name *",
    _UiTextKey.nameIsRequired: "Name is required",
    _UiTextKey.industry: "Industry",
    _UiTextKey.formSaved: "Form saved",
    _UiTextKey.formEditor: "Form Editor",
    _UiTextKey.fieldTypes: "Field Types",
    _UiTextKey.formName: "Form name",
    _UiTextKey.clickAFieldTypeToAddIt: "Click a field type to add it",
    _UiTextKey.requiredText3: " · Required",
    _UiTextKey.fieldProperties: "Field Properties",
    _UiTextKey.placeholder: "Placeholder",
    _UiTextKey.helpText: "Help text",
    _UiTextKey.readOnly: "Read only",
    _UiTextKey.hidden: "Hidden",
    _UiTextKey.options: "Options",
    _UiTextKey.add: "Add",
    _UiTextKey.newForm: "New Form",
    _UiTextKey.formDefinitions: "Form Definitions",
    _UiTextKey.buildStructuredFormsThatCaptureReliableDataGuideUsersBeautif:
        "Build structured forms that capture reliable data, guide users beautifully, and feed your workflows without friction.",
    _UiTextKey.searchForms: "Search forms...",
    _UiTextKey.noFormsYet: "No forms yet",
    _UiTextKey.createYourFirstFormDefinition:
        "Create your first form definition",
    _UiTextKey.createForm: "Create Form",
    _UiTextKey.deleteForm: "Delete Form",
    _UiTextKey.thisWillDeleteTheFormPermanently:
        "This will delete the form permanently.",
    _UiTextKey.totalForms: "Total Forms",
    _UiTextKey.totalFields: "Total Fields",
    _UiTextKey.fieldTypesDistribution: "Field Types Distribution",
    _UiTextKey.countOfEachFieldTypeAcrossAllForms:
        "Count of each field type across all forms",
    _UiTextKey.noFieldsDefined: "No fields defined",
    _UiTextKey.userSaved: "User saved",
    _UiTextKey.newUser: "New User",
    _UiTextKey.editUser: "Edit User",
    _UiTextKey.changePhoto: "Change photo",
    _UiTextKey.uploadPhoto: "Upload photo",
    _UiTextKey.userInfo: "User Info",
    _UiTextKey.firstNameRequired: "First name *",
    _UiTextKey.lastNameRequired: "Last name *",
    _UiTextKey.emailRequired: "Email *",
    _UiTextKey.phone: "Phone",
    _UiTextKey.passwordRequired: "Password *",
    _UiTextKey.newPasswordLeaveBlankToKeep:
        "New password (leave blank to keep)",
    _UiTextKey.access: "Access",
    _UiTextKey.noRole: "No role",
    _UiTextKey.assignedRole3: "Assigned role",
    _UiTextKey.activeAccount: "Active account",
    _UiTextKey.inactiveUsersCannotLogIn: "Inactive users cannot log in",
    _UiTextKey.all: "All",
    _UiTextKey.teamMembers: "Team Members",
    _UiTextKey.inviteTeammatesUnderstandAccountActivityAndBalanceRolesSoCol:
        "Invite teammates, understand account activity, and balance roles so collaboration stays organized and secure.",
    _UiTextKey.addUser: "Add User",
    _UiTextKey.searchMembers: "Search members...",
    _UiTextKey.noMembersFound: "No members found",
    _UiTextKey.tryAdjustingYourSearchOrFilters:
        "Try adjusting your search or filters",
    _UiTextKey.removeUser: "Remove User",
    _UiTextKey.removeThisUserFromTheSystem: "Remove this user from the system?",
    _UiTextKey.totalMembers: "Total Members",
    _UiTextKey.admins: "Admins",
    _UiTextKey.roleDistribution: "Role Distribution",
    _UiTextKey.membersByAssignedRole: "Members by assigned role",
    _UiTextKey.statusOverview: "Status Overview",
    _UiTextKey.accountActivity: "Account activity",
    _UiTextKey.inactive: "Inactive",
    _UiTextKey.remove: "Remove",
    _UiTextKey.roleSaved: "Role saved",
    _UiTextKey.newRole: "New Role",
    _UiTextKey.editRole: "Edit Role",
    _UiTextKey.roleDetails: "Role Details",
    _UiTextKey.roleNameRequired: "Role name *",
    _UiTextKey.owner: "Owner",
    _UiTextKey.manager: "Manager",
    _UiTextKey.member: "Member",
    _UiTextKey.viewer: "Viewer",
    _UiTextKey.accessLevel: "Access level",
    _UiTextKey.permissionCoverage: "Permission Coverage",
    _UiTextKey.permissions: "Permissions",
    _UiTextKey.configureCrudPermissionsPerResource:
        "Configure CRUD permissions per resource",
    _UiTextKey.resource: "Resource",
    _UiTextKey.create: "Create",
    _UiTextKey.read: "Read",
    _UiTextKey.update: "Update",
    _UiTextKey.rolesPermissions: "Roles & Permissions",
    _UiTextKey.shapeSecureAccessPoliciesClarifyResponsibilitiesAndGiveEvery:
        "Shape secure access policies, clarify responsibilities, and give every teammate exactly the permissions they need.",
    _UiTextKey.searchRoles: "Search roles...",
    _UiTextKey.noRolesYet: "No roles yet",
    _UiTextKey.createRolesToManageAccessControl:
        "Create roles to manage access control",
    _UiTextKey.createRole: "Create Role",
    _UiTextKey.deleteRole: "Delete Role",
    _UiTextKey.deleteThisRolePermanently: "Delete this role permanently?",
    _UiTextKey.totalRoles: "Total Roles",
    _UiTextKey.permissionSets: "Permission Sets",
    _UiTextKey.membersPerRole: "Members per Role",
    _UiTextKey.howManyUsersAreAssignedToEachRole:
        "How many users are assigned to each role",
    _UiTextKey.open: "Open",
    _UiTextKey.inProgress: "In Progress",
    _UiTextKey.resolved: "Resolved",
    _UiTextKey.closed: "Closed",
    _UiTextKey.supportTickets: "Support Tickets",
    _UiTextKey.trackCustomerRequestsPrioritizeUrgentWorkAndKeepEveryResolut:
        "Track customer requests, prioritize urgent work, and keep every resolution moving from one polished command center.",
    _UiTextKey.newTicket: "New Ticket",
    _UiTextKey.searchTickets: "Search tickets...",
    _UiTextKey.noTicketsFound: "No tickets found",
    _UiTextKey.tryAdjustingYourFilters: "Try adjusting your filters",
    _UiTextKey.total: "Total",
    _UiTextKey.low: "Low",
    _UiTextKey.med: "Med",
    _UiTextKey.high: "High",
    _UiTextKey.urgent: "Urgent",
    _UiTextKey.priorityBreakdown: "Priority Breakdown",
    _UiTextKey.ticketsByPriorityLevel: "Tickets by priority level",
    _UiTextKey.statusDistribution: "Status Distribution",
    _UiTextKey.currentTicketStates: "Current ticket states",
    _UiTextKey.noData: "No data",
    _UiTextKey.dueToday: "Due today",
    _UiTextKey.titleRequired: "Title *",
    _UiTextKey.titleIsRequired: "Title is required",
    _UiTextKey.priority: "Priority",
    _UiTextKey.attachment: "📎 Attachment",
    _UiTextKey.ticketMessageSent: "ticket.message_sent",
    _UiTextKey.ticketid: "ticketId",
    _UiTextKey.noMessagesYet: "No messages yet",
    _UiTextKey.attachFile: "Attach file",
    _UiTextKey.typeAMessage: "Type a message...",
    _UiTextKey.ticketDetails: "Ticket Details",
    _UiTextKey.status: "Status",
    _UiTextKey.creator: "Creator",
    _UiTextKey.assignee: "Assignee",
    _UiTextKey.dueDate: "Due date",
    _UiTextKey.slaProgress: "SLA Progress",
    _UiTextKey.tags: "Tags",
    _UiTextKey.deltacontent: "deltaContent",
    _UiTextKey.templateSaved: "Template saved",
    _UiTextKey.templateName: "Template name",
    _UiTextKey.attach: "Attach",
    _UiTextKey.variables: "Variables",
    _UiTextKey.addMore: "Add more",
    _UiTextKey.startWritingYourLetterTemplate:
        "Start writing your letter template...",
    _UiTextKey.availableVariables: "Available Variables",
    _UiTextKey.useTheseVariablesInYourTemplateTheyWillBeReplacedWithActualV:
        "Use these variables in your template. They will be replaced with actual values when the letter is generated.",
    _UiTextKey.userSFullName: "User's full name",
    _UiTextKey.userSEmail: "User's email",
    _UiTextKey.companyName: "Company name",
    _UiTextKey.currentDate: "Current date",
    _UiTextKey.flowName: "Flow name",
    _UiTextKey.newLetterTemplate: "New Letter Template",
    _UiTextKey.uncategorized: "Uncategorized",
    _UiTextKey.letterTemplates: "Letter Templates",
    _UiTextKey.manageReusableLetterTemplatesWithDynamicVariablesReadyToSend:
        "Manage reusable letter templates with dynamic variables, ready-to-send language, and consistent branded communication.",
    _UiTextKey.newTemplate: "New Template",
    _UiTextKey.searchTemplates: "Search templates...",
    _UiTextKey.noLetterTemplates: "No letter templates",
    _UiTextKey.createReusableLetterTemplates:
        "Create reusable letter templates",
    _UiTextKey.createTemplate: "Create Template",
    _UiTextKey.deleteTemplate: "Delete Template",
    _UiTextKey.deleteThisLetterTemplatePermanently:
        "Delete this letter template permanently?",
    _UiTextKey.totalTemplates: "Total Templates",
    _UiTextKey.totalVariables: "Total Variables",
    _UiTextKey.templatesByCategory: "Templates by Category",
    _UiTextKey.distributionAcrossCategories: "Distribution across categories",
    _UiTextKey.allCategories: "All categories",
    _UiTextKey.goodMorning: "Good morning",
    _UiTextKey.goodAfternoon: "Good afternoon",
    _UiTextKey.goodEvening: "Good evening",
    _UiTextKey.mon: "Mon",
    _UiTextKey.tue: "Tue",
    _UiTextKey.wed: "Wed",
    _UiTextKey.thu: "Thu",
    _UiTextKey.fri: "Fri",
    _UiTextKey.sat: "Sat",
    _UiTextKey.sun: "Sun",
    _UiTextKey.jan: "Jan",
    _UiTextKey.feb: "Feb",
    _UiTextKey.mar: "Mar",
    _UiTextKey.apr: "Apr",
    _UiTextKey.may: "May",
    _UiTextKey.jun: "Jun",
    _UiTextKey.jul: "Jul",
    _UiTextKey.aug: "Aug",
    _UiTextKey.sep: "Sep",
    _UiTextKey.oct: "Oct",
    _UiTextKey.nov: "Nov",
    _UiTextKey.dec: "Dec",
    _UiTextKey.hereSWhatSHappeningInYourOrganizationToday:
        "Here's what's happening in your organization today.",
    _UiTextKey.activeOrganizations: "Active organizations",
    _UiTextKey.activeFlows: "Active Flows",
    _UiTextKey.automationPipelines: "Automation pipelines",
    _UiTextKey.openTickets: "Open Tickets",
    _UiTextKey.needsAttention: "Needs attention",
    _UiTextKey.closedTickets: "Closed tickets",
    _UiTextKey.activityOverview: "Activity Overview",
    _UiTextKey.ticketsFlowsLast7Days: "Tickets & flows – last 7 days",
    _UiTextKey.tickets: "Tickets",
    _UiTextKey.ticketStatus: "Ticket Status",
    _UiTextKey.distributionOverview: "Distribution overview",
    _UiTextKey.noTicketsYet: "No tickets yet",
    _UiTextKey.recentTickets: "Recent Tickets",
    _UiTextKey.latestActivity: "Latest activity",
    _UiTextKey.viewAll: "View all",
    _UiTextKey.resolutionRate: "Resolution Rate",
    _UiTextKey.slaCompliance: "SLA Compliance",
    _UiTextKey.performanceMetrics: "Performance Metrics",
    _UiTextKey.ticketKpisAtAGlance: "Ticket KPIs at a glance",
    _UiTextKey.quickActions: "Quick Actions",
    _UiTextKey.modelSaved: "Model saved",
    _UiTextKey.modelEditor: "Model Editor",
    _UiTextKey.modelInfo: "Model Info",
    _UiTextKey.modelNameRequired: "Model name *",
    _UiTextKey.addField: "Add Field",
    _UiTextKey.noFieldsYetAddYourFirstField:
        "No fields yet. Add your first field.",
    _UiTextKey.jsonSchemaPreview: "JSON Schema Preview",
    _UiTextKey.text3: " : ",
    _UiTextKey.unique: " · Unique",
    _UiTextKey.unique3: "Unique",
    _UiTextKey.fieldNameRequired: "Field name *",
    _UiTextKey.fieldType: "Field type",
    _UiTextKey.newModel: "New Model",
    _UiTextKey.dataModels: "Data Models",
    _UiTextKey.defineDurableEntitySchemasOrganizeFieldsAndKeepYourOperation:
        "Define durable entity schemas, organize fields, and keep your operational data consistent across every product surface.",
    _UiTextKey.searchModels: "Search models...",
    _UiTextKey.noModelsYet: "No models yet",
    _UiTextKey.defineYourDataStructures: "Define your data structures",
    _UiTextKey.createModel: "Create Model",
    _UiTextKey.deleteModel: "Delete Model",
    _UiTextKey.deleteThisModelPermanently: "Delete this model permanently?",
    _UiTextKey.totalModels: "Total Models",
    _UiTextKey.fieldTypeDistribution: "Field Type Distribution",
    _UiTextKey.breakdownOfFieldTypesAcrossAllModels:
        "Breakdown of field types across all models",
    _UiTextKey.editLabel: "Edit label",
    _UiTextKey.deleteEdge: "Delete edge",
    _UiTextKey.yes: "Yes",
    _UiTextKey.no: "No",
    _UiTextKey.form: "Form",
    _UiTextKey.role: "Role",
    _UiTextKey.y: "Y",
    _UiTextKey.n3: "N",
    _UiTextKey.ellipsis: "…",
    _UiTextKey.noNodes: "No nodes",
    _UiTextKey.dashboard: "Dashboard",
    _UiTextKey.overview: "Overview",
    _UiTextKey.organization: "Organization",
    _UiTextKey.users: "Users",
    _UiTextKey.roles: "Roles",
    _UiTextKey.automation: "Automation",
    _UiTextKey.forms: "Forms",
    _UiTextKey.models: "Models",
    _UiTextKey.letters: "Letters",
    _UiTextKey.communication: "Communication",
    _UiTextKey.menu: "Menu",
    _UiTextKey.search: "Search",
    _UiTextKey.notifications: "Notifications",
    _UiTextKey.toggleTheme: "Toggle theme",
    _UiTextKey.search3: "Search...",
    _UiTextKey.disableGlassMode: "Disable glass mode",
    _UiTextKey.enableGlassMode: "Enable glass mode",
    _UiTextKey.logout: "Logout",
    _UiTextKey.signOut: "Sign Out",
    _UiTextKey.select: "Select...",
    _UiTextKey.selectDate: "Select date",
    _UiTextKey.selectTime: "Select time",
    _UiTextKey.clickToUploadFile: "Click to upload file",
    _UiTextKey.anyFileTypeSupported: "Any file type supported",
    _UiTextKey.clickToUploadImage: "Click to upload image",
    _UiTextKey.pngJpgGifSupported: "PNG, JPG, GIF supported",
    _UiTextKey.pickAColor: "Pick a color",
    _UiTextKey.done: "Done",
    _UiTextKey.signHere: "Sign here",
    _UiTextKey.column1: "Column 1",
    _UiTextKey.column2: "Column 2",
    _UiTextKey.column3: "Column 3",
    _UiTextKey.addRow: "Add Row",
    _UiTextKey.searchEllipsis: "Search…",
    _UiTextKey.somethingWentWrong: "Something went wrong",
    _UiTextKey.retry: "Retry",
    _UiTextKey.string: "String",
    _UiTextKey.integer: "Integer",
    _UiTextKey.float: "Float",
    _UiTextKey.boolean: "Boolean",
    _UiTextKey.date: "Date",
    _UiTextKey.dateTime: "DateTime",
    _UiTextKey.file: "File",
    _UiTextKey.reference: "Reference",
    _UiTextKey.textField: "Text",
    _UiTextKey.number: "Number",
    _UiTextKey.textArea: "Text Area",
    _UiTextKey.dropdown: "Dropdown",
    _UiTextKey.multiSelect: "Multi-Select",
    _UiTextKey.checkbox: "Checkbox",
    _UiTextKey.radioGroup: "Radio Group",
    _UiTextKey.datePicker: "Date Picker",
    _UiTextKey.timePicker: "Time Picker",
    _UiTextKey.fileUpload: "File Upload",
    _UiTextKey.imageUpload: "Image Upload",
    _UiTextKey.colorPicker: "Color Picker",
    _UiTextKey.switchText: "Switch",
    _UiTextKey.table: "Table",
    _UiTextKey.rating: "Rating",
    _UiTextKey.signature: "Signature",
    _UiTextKey.medium: "Medium",
    _UiTextKey.there: "there",
    _UiTextKey.emptyJsonObject: "{}",
    _UiTextKey.bulletSeparator: " · ",
    _UiTextKey.requiredAsterisk: "*",
    _UiTextKey.schemaSeparator: ",\n",
    _UiTextKey.step: "Step",
    _UiTextKey.decision: "Decision",
    _UiTextKey.instances: "Instances",
    _UiTextKey.approved: "Approved",
    _UiTextKey.pending: "Pending",
    _UiTextKey.rejected: "Rejected",
  };

  static const Map<_UiTextKey, String> _persian = {
    _UiTextKey.exception: "استثنا: ",
    _UiTextKey.autocreat: "اتوکریت",
    _UiTextKey.createYourAccount: "ایجاد حساب کاربری",
    _UiTextKey.startBuildingYourOrganizationalSystem:
        "ساخت سیستم سازمانی خود را شروع کنید",
    _UiTextKey.firstName: "نام",
    _UiTextKey.requiredText: "الزامی",
    _UiTextKey.lastName: "نام خانوادگی",
    _UiTextKey.emailAddress: "آدرس ایمیل",
    _UiTextKey.emailIsRequired: "ایمیل الزامی است",
    _UiTextKey.invalidEmail: "ایمیل نامعتبر است",
    _UiTextKey.companyNameOptional: "نام شرکت (اختیاری)",
    _UiTextKey.password: "رمز عبور",
    _UiTextKey.passwordIsRequired: "رمز عبور الزامی است",
    _UiTextKey.atLeast8Characters: "حداقل ۸ کاراکتر",
    _UiTextKey.confirmPassword: "تأیید رمز عبور",
    _UiTextKey.passwordsDoNotMatch: "رمزهای عبور مطابقت ندارند",
    _UiTextKey.createAccount: "ایجاد حساب",
    _UiTextKey.alreadyHaveAnAccount: "قبلاً حساب دارید؟ ",
    _UiTextKey.signIn: "ورود",
    _UiTextKey.demo123: "Demo123!",
    _UiTextKey.demo: "نمایشی",
    _UiTextKey.admin: "مدیر",
    _UiTextKey.welcomeBack: "خوش آمدید",
    _UiTextKey.signInToYourOrganizationAccount: "به حساب سازمان خود وارد شوید",
    _UiTextKey.passwordTooShort: "رمز عبور خیلی کوتاه است",
    _UiTextKey.forgotPassword: "رمز عبور را فراموش کرده‌اید؟",
    _UiTextKey.signIn3: "ورود",
    _UiTextKey.donTHaveAnAccount: "حساب ندارید؟ ",
    _UiTextKey.createAccount3: "ایجاد حساب",
    _UiTextKey.demo3: "نمایشی",
    _UiTextKey.tryDemoMode: "ورود به حالت نمایشی",
    _UiTextKey.noAccountNeededExploreWithSampleData:
        "بدون نیاز به حساب — با داده‌های نمونه کاوش کنید",
    _UiTextKey.organizationalSystemBuilder: "سازنده سیستم سازمانی",
    _UiTextKey.designComplexOrganizationalFlows:
        "طراحی جریان‌های سازمانی پیچیده",
    _UiTextKey.buildFormsAndDataModels: "ساخت فرم‌ها و مدل‌های داده",
    _UiTextKey.manageRolesAndPermissions: "مدیریت نقش‌ها و مجوزها",
    _UiTextKey.communicateViaTickets: "ارتباط از طریق تیکت‌ها",
    _UiTextKey.flowSaved: "جریان ذخیره شد",
    _UiTextKey.editNodeLabel: "ویرایش برچسب گره",
    _UiTextKey.label: "برچسب",
    _UiTextKey.cancel: "لغو",
    _UiTextKey.save: "ذخیره",
    _UiTextKey.canvasControls: "کنترل‌های بوم",
    _UiTextKey.zoomOut: "کوچک‌نمایی",
    _UiTextKey.zoomIn: "بزرگ‌نمایی",
    _UiTextKey.fitScreen: "تناسب با صفحه",
    _UiTextKey.autoLayout: "چیدمان خودکار",
    _UiTextKey.flowEditor: "ویرایشگر جریان",
    _UiTextKey.unsaved: "ذخیره‌نشده",
    _UiTextKey.zoomOut3: "کوچک‌نمایی",
    _UiTextKey.zoomIn3: "بزرگ‌نمایی",
    _UiTextKey.canvasControls3: "کنترل‌های بوم",
    _UiTextKey.saveFlow: "ذخیره جریان",
    _UiTextKey.addStartNode: "افزودن گره شروع",
    _UiTextKey.addStepNode: "افزودن گره مرحله",
    _UiTextKey.addDecisionNode: "افزودن گره تصمیم",
    _UiTextKey.addEndNode: "افزودن گره پایان",
    _UiTextKey.fitToScreen: "تنظیم به صفحه",
    _UiTextKey.nodeProperties: "ویژگی‌های گره",
    _UiTextKey.deleteNode: "حذف گره",
    _UiTextKey.close: "بستن",
    _UiTextKey.startBuildingYourFlow: "شروع به ساخت جریان",
    _UiTextKey.tapHereToAddAStartNodeNorUseTheToolbarOnTheLeft:
        "اینجا کلیک کنید تا گره شروع اضافه کنید،\nیا از نوار ابزار استفاده کنید.",
    _UiTextKey.newFlow: "جریان جدید",
    _UiTextKey.start: "شروع",
    _UiTextKey.end: "پایان",
    _UiTextKey.automationFlows: "جریان‌های اتوماسیون",
    _UiTextKey.designReviewAndLaunchOrganizationalProcessFlowsWithClearStep:
        "طراحی، بررسی و راه‌اندازی جریان‌های فرآیند سازمانی با مراحل واضح، تصمیم‌های متصل و نتایج قابل اندازه‌گیری.",
    _UiTextKey.newText: "جدید",
    _UiTextKey.searchFlows: "جستجو جریان‌ها...",
    _UiTextKey.noFlowsYet: "هنوز جریانی وجود ندارد",
    _UiTextKey.createYourFirstOrganizationalFlow:
        "اولین جریان سازمانی خود را بسازید",
    _UiTextKey.createFlow: "ایجاد جریان",
    _UiTextKey.deleteFlow: "حذف جریان",
    _UiTextKey.thisWillDeleteTheFlowPermanently:
        "این جریان به طور دائمی حذف خواهد شد.",
    _UiTextKey.totalFlows: "کل جریان‌ها",
    _UiTextKey.active: "فعال",
    _UiTextKey.draft: "پیش‌نویس",
    _UiTextKey.totalNodes: "کل گره‌ها",
    _UiTextKey.flowComplexity: "پیچیدگی جریان",
    _UiTextKey.nodesAndEdgesPerFlow: "گره‌ها و یال‌ها در هر جریان",
    _UiTextKey.nodeTypes: "انواع گره",
    _UiTextKey.openEditor: "باز کردن ویرایشگر",
    _UiTextKey.delete: "حذف",
    _UiTextKey.nodeLabel: "برچسب گره",
    _UiTextKey.enterLabelEllipsis: "برچسب را وارد کنید…",
    _UiTextKey.description: "توضیح",
    _UiTextKey.optionalDescriptionEllipsis: "توضیح اختیاری…",
    _UiTextKey.assignedRole: "نقش تخصیص‌یافته",
    _UiTextKey.errorLoadingRoles: "خطا در بارگذاری نقش‌ها",
    _UiTextKey.noRoleAssigned: "نقشی تخصیص نیافته",
    _UiTextKey.selectRoleEllipsis: "انتخاب نقش…",
    _UiTextKey.assignedForm: "فرم تخصیص‌یافته",
    _UiTextKey.errorLoadingForms: "خطا در بارگذاری فرم‌ها",
    _UiTextKey.noFormAssigned: "فرمی تخصیص نیافته",
    _UiTextKey.selectFormEllipsis: "انتخاب فرم…",
    _UiTextKey.branches: "شاخه‌ها",
    _UiTextKey.addBranch: "افزودن شاخه",
    _UiTextKey.defaultText: "پیش‌فرض",
    _UiTextKey.conditionEGStatusApproved: "شرط (مثلاً: وضعیت == تأییدشده)",
    _UiTextKey.position: "موقعیت",
    _UiTextKey.capacity: "ظرفیت",
    _UiTextKey.members: "اعضا",
    _UiTextKey.flows: "جریان‌ها",
    _UiTextKey.details: "جزئیات",
    _UiTextKey.website: "وب‌سایت",
    _UiTextKey.created: "ایجادشده",
    _UiTextKey.text: ".",
    _UiTextKey.companies: "شرکت‌ها",
    _UiTextKey.organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK:
        "فضاهای کاری مشتریان و شرکا را سازماندهی کنید، سلامت پورتفولیو را رصد کنید و هر سازمان را به آسانی پیدا و مدیریت کنید.",
    _UiTextKey.newCompany: "شرکت جدید",
    _UiTextKey.searchCompanies: "جستجو شرکت‌ها...",
    _UiTextKey.noCompaniesYet: "هنوز شرکتی وجود ندارد",
    _UiTextKey.noResultsFound: "نتیجه‌ای یافت نشد",
    _UiTextKey.createYourFirstCompanyToGetStarted:
        "اولین شرکت خود را برای شروع بسازید",
    _UiTextKey.createCompany: "ایجاد شرکت",
    _UiTextKey.deleteCompany: "حذف شرکت",
    _UiTextKey.areYouSureYouWantToDeleteThisCompany:
        "آیا مطمئن هستید که می‌خواهید این شرکت را حذف کنید؟",
    _UiTextKey.edit: "ویرایش",
    _UiTextKey.editCompany: "ویرایش شرکت",
    _UiTextKey.companyNameRequired: "نام شرکت *",
    _UiTextKey.nameIsRequired: "نام الزامی است",
    _UiTextKey.industry: "صنعت",
    _UiTextKey.formSaved: "فرم ذخیره شد",
    _UiTextKey.formEditor: "ویرایشگر فرم",
    _UiTextKey.fieldTypes: "انواع فیلد",
    _UiTextKey.formName: "نام فرم",
    _UiTextKey.clickAFieldTypeToAddIt: "روی یک نوع فیلد کلیک کنید تا اضافه شود",
    _UiTextKey.requiredText3: " · الزامی",
    _UiTextKey.fieldProperties: "ویژگی‌های فیلد",
    _UiTextKey.placeholder: "متن نمونه",
    _UiTextKey.helpText: "متن راهنما",
    _UiTextKey.readOnly: "فقط خواندنی",
    _UiTextKey.hidden: "پنهان",
    _UiTextKey.options: "گزینه‌ها",
    _UiTextKey.add: "افزودن",
    _UiTextKey.newForm: "فرم جدید",
    _UiTextKey.formDefinitions: "تعریف فرم‌ها",
    _UiTextKey.buildStructuredFormsThatCaptureReliableDataGuideUsersBeautif:
        "فرم‌های ساختاریافته بسازید که داده‌های قابل اعتماد جمع‌آوری می‌کنند، کاربران را زیبا راهنمایی می‌کنند و گردش کار شما را بدون اصطکاک تأمین می‌کنند.",
    _UiTextKey.searchForms: "جستجو فرم‌ها...",
    _UiTextKey.noFormsYet: "هنوز فرمی وجود ندارد",
    _UiTextKey.createYourFirstFormDefinition: "اولین تعریف فرم خود را بسازید",
    _UiTextKey.createForm: "ایجاد فرم",
    _UiTextKey.deleteForm: "حذف فرم",
    _UiTextKey.thisWillDeleteTheFormPermanently:
        "این فرم به طور دائمی حذف خواهد شد.",
    _UiTextKey.totalForms: "کل فرم‌ها",
    _UiTextKey.totalFields: "کل فیلدها",
    _UiTextKey.fieldTypesDistribution: "توزیع انواع فیلد",
    _UiTextKey.countOfEachFieldTypeAcrossAllForms:
        "تعداد هر نوع فیلد در تمام فرم‌ها",
    _UiTextKey.noFieldsDefined: "هیچ فیلدی تعریف نشده",
    _UiTextKey.userSaved: "کاربر ذخیره شد",
    _UiTextKey.newUser: "کاربر جدید",
    _UiTextKey.editUser: "ویرایش کاربر",
    _UiTextKey.changePhoto: "تغییر عکس",
    _UiTextKey.uploadPhoto: "بارگذاری عکس",
    _UiTextKey.userInfo: "اطلاعات کاربر",
    _UiTextKey.firstNameRequired: "نام *",
    _UiTextKey.lastNameRequired: "نام خانوادگی *",
    _UiTextKey.emailRequired: "ایمیل *",
    _UiTextKey.phone: "تلفن",
    _UiTextKey.passwordRequired: "رمز عبور *",
    _UiTextKey.newPasswordLeaveBlankToKeep:
        "رمز عبور جدید (برای نگه‌داشتن، خالی بگذارید)",
    _UiTextKey.access: "دسترسی",
    _UiTextKey.noRole: "بدون نقش",
    _UiTextKey.assignedRole3: "نقش تخصیص‌یافته",
    _UiTextKey.activeAccount: "حساب فعال",
    _UiTextKey.inactiveUsersCannotLogIn: "کاربران غیرفعال نمی‌توانند وارد شوند",
    _UiTextKey.all: "همه",
    _UiTextKey.teamMembers: "اعضای تیم",
    _UiTextKey.inviteTeammatesUnderstandAccountActivityAndBalanceRolesSoCol:
        "همکاران را دعوت کنید، فعالیت حساب را بررسی کنید و نقش‌ها را متعادل کنید تا همکاری سازماندهی‌شده و ایمن باشد.",
    _UiTextKey.addUser: "افزودن کاربر",
    _UiTextKey.searchMembers: "جستجو اعضا...",
    _UiTextKey.noMembersFound: "عضوی یافت نشد",
    _UiTextKey.tryAdjustingYourSearchOrFilters:
        "جستجو یا فیلترهای خود را تنظیم کنید",
    _UiTextKey.removeUser: "حذف کاربر",
    _UiTextKey.removeThisUserFromTheSystem:
        "این کاربر را از سیستم حذف کنیم؟",
    _UiTextKey.totalMembers: "کل اعضا",
    _UiTextKey.admins: "مدیران",
    _UiTextKey.roleDistribution: "توزیع نقش‌ها",
    _UiTextKey.membersByAssignedRole: "اعضا بر اساس نقش تخصیص‌یافته",
    _UiTextKey.statusOverview: "نمای کلی وضعیت",
    _UiTextKey.accountActivity: "فعالیت حساب",
    _UiTextKey.inactive: "غیرفعال",
    _UiTextKey.remove: "حذف",
    _UiTextKey.roleSaved: "نقش ذخیره شد",
    _UiTextKey.newRole: "نقش جدید",
    _UiTextKey.editRole: "ویرایش نقش",
    _UiTextKey.roleDetails: "جزئیات نقش",
    _UiTextKey.roleNameRequired: "نام نقش *",
    _UiTextKey.owner: "مالک",
    _UiTextKey.manager: "مدیر",
    _UiTextKey.member: "عضو",
    _UiTextKey.viewer: "بیننده",
    _UiTextKey.accessLevel: "سطح دسترسی",
    _UiTextKey.permissionCoverage: "پوشش مجوزها",
    _UiTextKey.permissions: "مجوزها",
    _UiTextKey.configureCrudPermissionsPerResource:
        "تنظیم مجوزهای CRUD برای هر منبع",
    _UiTextKey.resource: "منبع",
    _UiTextKey.create: "ایجاد",
    _UiTextKey.read: "خواندن",
    _UiTextKey.update: "به‌روزرسانی",
    _UiTextKey.rolesPermissions: "نقش‌ها و مجوزها",
    _UiTextKey.shapeSecureAccessPoliciesClarifyResponsibilitiesAndGiveEvery:
        "سیاست‌های دسترسی امن تعریف کنید، مسئولیت‌ها را مشخص کنید و به هر همکار دقیقاً مجوزهایی که نیاز دارد بدهید.",
    _UiTextKey.searchRoles: "جستجو نقش‌ها...",
    _UiTextKey.noRolesYet: "هنوز نقشی وجود ندارد",
    _UiTextKey.createRolesToManageAccessControl:
        "نقش‌هایی برای مدیریت کنترل دسترسی بسازید",
    _UiTextKey.createRole: "ایجاد نقش",
    _UiTextKey.deleteRole: "حذف نقش",
    _UiTextKey.deleteThisRolePermanently: "این نقش را به طور دائمی حذف کنیم؟",
    _UiTextKey.totalRoles: "کل نقش‌ها",
    _UiTextKey.permissionSets: "مجموعه مجوزها",
    _UiTextKey.membersPerRole: "اعضا در هر نقش",
    _UiTextKey.howManyUsersAreAssignedToEachRole:
        "تعداد کاربران تخصیص‌یافته به هر نقش",
    _UiTextKey.open: "باز",
    _UiTextKey.inProgress: "در حال انجام",
    _UiTextKey.resolved: "حل‌شده",
    _UiTextKey.closed: "بسته",
    _UiTextKey.supportTickets: "تیکت‌های پشتیبانی",
    _UiTextKey.trackCustomerRequestsPrioritizeUrgentWorkAndKeepEveryResolut:
        "درخواست‌های مشتریان را پیگیری کنید، کارهای فوری را اولویت‌بندی کنید و هر حل‌وفصلی را از یک مرکز فرماندهی مدیریت کنید.",
    _UiTextKey.newTicket: "تیکت جدید",
    _UiTextKey.searchTickets: "جستجو تیکت‌ها...",
    _UiTextKey.noTicketsFound: "تیکتی یافت نشد",
    _UiTextKey.tryAdjustingYourFilters: "فیلترهای خود را تنظیم کنید",
    _UiTextKey.total: "کل",
    _UiTextKey.low: "کم",
    _UiTextKey.med: "متوسط",
    _UiTextKey.high: "زیاد",
    _UiTextKey.urgent: "فوری",
    _UiTextKey.priorityBreakdown: "تحلیل اولویت",
    _UiTextKey.ticketsByPriorityLevel: "تیکت‌ها بر اساس سطح اولویت",
    _UiTextKey.statusDistribution: "توزیع وضعیت",
    _UiTextKey.currentTicketStates: "وضعیت فعلی تیکت‌ها",
    _UiTextKey.noData: "داده‌ای وجود ندارد",
    _UiTextKey.dueToday: "سررسید امروز",
    _UiTextKey.titleRequired: "عنوان *",
    _UiTextKey.titleIsRequired: "عنوان الزامی است",
    _UiTextKey.priority: "اولویت",
    _UiTextKey.attachment: "📎 پیوست",
    _UiTextKey.ticketMessageSent: "ticket.message_sent",
    _UiTextKey.ticketid: "ticketId",
    _UiTextKey.noMessagesYet: "هنوز پیامی وجود ندارد",
    _UiTextKey.attachFile: "پیوست فایل",
    _UiTextKey.typeAMessage: "پیامی بنویسید...",
    _UiTextKey.ticketDetails: "جزئیات تیکت",
    _UiTextKey.status: "وضعیت",
    _UiTextKey.creator: "ایجادکننده",
    _UiTextKey.assignee: "مسئول",
    _UiTextKey.dueDate: "تاریخ سررسید",
    _UiTextKey.slaProgress: "پیشرفت SLA",
    _UiTextKey.tags: "برچسب‌ها",
    _UiTextKey.deltacontent: "deltaContent",
    _UiTextKey.templateSaved: "قالب ذخیره شد",
    _UiTextKey.templateName: "نام قالب",
    _UiTextKey.attach: "پیوست",
    _UiTextKey.variables: "متغیرها",
    _UiTextKey.addMore: "افزودن بیشتر",
    _UiTextKey.startWritingYourLetterTemplate: "شروع به نوشتن قالب نامه...",
    _UiTextKey.availableVariables: "متغیرهای موجود",
    _UiTextKey.useTheseVariablesInYourTemplateTheyWillBeReplacedWithActualV:
        "از این متغیرها در قالب خود استفاده کنید. آن‌ها هنگام تولید نامه با مقادیر واقعی جایگزین می‌شوند.",
    _UiTextKey.userSFullName: "نام کامل کاربر",
    _UiTextKey.userSEmail: "ایمیل کاربر",
    _UiTextKey.companyName: "نام شرکت",
    _UiTextKey.currentDate: "تاریخ جاری",
    _UiTextKey.flowName: "نام جریان",
    _UiTextKey.newLetterTemplate: "قالب نامه جدید",
    _UiTextKey.uncategorized: "دسته‌بندی‌نشده",
    _UiTextKey.letterTemplates: "قالب‌های نامه",
    _UiTextKey.manageReusableLetterTemplatesWithDynamicVariablesReadyToSend:
        "قالب‌های نامه قابل‌استفاده مجدد با متغیرهای پویا، متن آماده برای ارسال و ارتباطات برند‌شده یکپارچه را مدیریت کنید.",
    _UiTextKey.newTemplate: "قالب جدید",
    _UiTextKey.searchTemplates: "جستجو قالب‌ها...",
    _UiTextKey.noLetterTemplates: "هیچ قالب نامه‌ای وجود ندارد",
    _UiTextKey.createReusableLetterTemplates: "قالب‌های نامه قابل استفاده مجدد بسازید",
    _UiTextKey.createTemplate: "ایجاد قالب",
    _UiTextKey.deleteTemplate: "حذف قالب",
    _UiTextKey.deleteThisLetterTemplatePermanently:
        "این قالب نامه را به طور دائمی حذف کنیم؟",
    _UiTextKey.totalTemplates: "کل قالب‌ها",
    _UiTextKey.totalVariables: "کل متغیرها",
    _UiTextKey.templatesByCategory: "قالب‌ها بر اساس دسته",
    _UiTextKey.distributionAcrossCategories: "توزیع در دسته‌ها",
    _UiTextKey.allCategories: "همه دسته‌ها",
    _UiTextKey.goodMorning: "صبح بخیر",
    _UiTextKey.goodAfternoon: "عصر بخیر",
    _UiTextKey.goodEvening: "شب بخیر",
    _UiTextKey.mon: "دوشنبه",
    _UiTextKey.tue: "سه‌شنبه",
    _UiTextKey.wed: "چهارشنبه",
    _UiTextKey.thu: "پنج‌شنبه",
    _UiTextKey.fri: "جمعه",
    _UiTextKey.sat: "شنبه",
    _UiTextKey.sun: "یکشنبه",
    _UiTextKey.jan: "ژانویه",
    _UiTextKey.feb: "فوریه",
    _UiTextKey.mar: "مارس",
    _UiTextKey.apr: "آوریل",
    _UiTextKey.may: "مه",
    _UiTextKey.jun: "ژوئن",
    _UiTextKey.jul: "ژوئیه",
    _UiTextKey.aug: "اوت",
    _UiTextKey.sep: "سپتامبر",
    _UiTextKey.oct: "اکتبر",
    _UiTextKey.nov: "نوامبر",
    _UiTextKey.dec: "دسامبر",
    _UiTextKey.hereSWhatSHappeningInYourOrganizationToday:
        "در اینجا ببینید چه اتفاقی در سازمان شما امروز می‌افتد.",
    _UiTextKey.activeOrganizations: "سازمان‌های فعال",
    _UiTextKey.activeFlows: "جریان‌های فعال",
    _UiTextKey.automationPipelines: "خطوط اتوماسیون",
    _UiTextKey.openTickets: "تیکت‌های باز",
    _UiTextKey.needsAttention: "نیاز به توجه",
    _UiTextKey.closedTickets: "تیکت‌های بسته",
    _UiTextKey.activityOverview: "نمای کلی فعالیت",
    _UiTextKey.ticketsFlowsLast7Days: "تیکت‌ها و جریان‌ها — ۷ روز گذشته",
    _UiTextKey.tickets: "تیکت‌ها",
    _UiTextKey.ticketStatus: "وضعیت تیکت",
    _UiTextKey.distributionOverview: "نمای کلی توزیع",
    _UiTextKey.noTicketsYet: "هنوز تیکتی وجود ندارد",
    _UiTextKey.recentTickets: "تیکت‌های اخیر",
    _UiTextKey.latestActivity: "آخرین فعالیت",
    _UiTextKey.viewAll: "مشاهده همه",
    _UiTextKey.resolutionRate: "نرخ حل‌وفصل",
    _UiTextKey.slaCompliance: "رعایت SLA",
    _UiTextKey.performanceMetrics: "معیارهای عملکرد",
    _UiTextKey.ticketKpisAtAGlance: "KPIهای تیکت در یک نگاه",
    _UiTextKey.quickActions: "اقدام‌های سریع",
    _UiTextKey.modelSaved: "مدل ذخیره شد",
    _UiTextKey.modelEditor: "ویرایشگر مدل",
    _UiTextKey.modelInfo: "اطلاعات مدل",
    _UiTextKey.modelNameRequired: "نام مدل *",
    _UiTextKey.addField: "افزودن فیلد",
    _UiTextKey.noFieldsYetAddYourFirstField:
        "هنوز فیلدی وجود ندارد. اولین فیلد خود را اضافه کنید.",
    _UiTextKey.jsonSchemaPreview: "پیش‌نمایش JSON Schema",
    _UiTextKey.text3: " : ",
    _UiTextKey.unique: " · یکتا",
    _UiTextKey.unique3: "یکتا",
    _UiTextKey.fieldNameRequired: "نام فیلد *",
    _UiTextKey.fieldType: "نوع فیلد",
    _UiTextKey.newModel: "مدل جدید",
    _UiTextKey.dataModels: "مدل‌های داده",
    _UiTextKey.defineDurableEntitySchemasOrganizeFieldsAndKeepYourOperation:
        "طرح‌های موجودیت پایدار تعریف کنید، فیلدها را سازماندهی کنید و داده‌های عملیاتی خود را در تمام سطوح محصول یکپارچه نگه دارید.",
    _UiTextKey.searchModels: "جستجو مدل‌ها...",
    _UiTextKey.noModelsYet: "هنوز مدلی وجود ندارد",
    _UiTextKey.defineYourDataStructures: "ساختارهای داده خود را تعریف کنید",
    _UiTextKey.createModel: "ایجاد مدل",
    _UiTextKey.deleteModel: "حذف مدل",
    _UiTextKey.deleteThisModelPermanently: "این مدل را به طور دائمی حذف کنیم؟",
    _UiTextKey.totalModels: "کل مدل‌ها",
    _UiTextKey.fieldTypeDistribution: "توزیع نوع فیلد",
    _UiTextKey.breakdownOfFieldTypesAcrossAllModels:
        "تحلیل انواع فیلد در تمام مدل‌ها",
    _UiTextKey.editLabel: "ویرایش برچسب",
    _UiTextKey.deleteEdge: "حذف یال",
    _UiTextKey.yes: "بله",
    _UiTextKey.no: "خیر",
    _UiTextKey.form: "فرم",
    _UiTextKey.role: "نقش",
    _UiTextKey.y: "ب",
    _UiTextKey.n3: "خ",
    _UiTextKey.ellipsis: "…",
    _UiTextKey.noNodes: "هیچ گره‌ای وجود ندارد",
    _UiTextKey.dashboard: "داشبورد",
    _UiTextKey.overview: "نمای کلی",
    _UiTextKey.organization: "سازمان",
    _UiTextKey.users: "کاربران",
    _UiTextKey.roles: "نقش‌ها",
    _UiTextKey.automation: "اتوماسیون",
    _UiTextKey.forms: "فرم‌ها",
    _UiTextKey.models: "مدل‌ها",
    _UiTextKey.letters: "نامه‌ها",
    _UiTextKey.communication: "ارتباطات",
    _UiTextKey.menu: "منو",
    _UiTextKey.search: "جستجو",
    _UiTextKey.notifications: "اعلان‌ها",
    _UiTextKey.toggleTheme: "تغییر پوسته",
    _UiTextKey.search3: "جستجو...",
    _UiTextKey.disableGlassMode: "غیرفعال کردن حالت شیشه‌ای",
    _UiTextKey.enableGlassMode: "فعال کردن حالت شیشه‌ای",
    _UiTextKey.logout: "خروج",
    _UiTextKey.signOut: "خروج",
    _UiTextKey.select: "انتخاب...",
    _UiTextKey.selectDate: "انتخاب تاریخ",
    _UiTextKey.selectTime: "انتخاب زمان",
    _UiTextKey.clickToUploadFile: "کلیک کنید تا فایل بارگذاری کنید",
    _UiTextKey.anyFileTypeSupported: "هر نوع فایلی پشتیبانی می‌شود",
    _UiTextKey.clickToUploadImage: "کلیک کنید تا تصویر بارگذاری کنید",
    _UiTextKey.pngJpgGifSupported: "PNG، JPG، GIF پشتیبانی می‌شوند",
    _UiTextKey.pickAColor: "انتخاب رنگ",
    _UiTextKey.done: "انجام شد",
    _UiTextKey.signHere: "اینجا امضا کنید",
    _UiTextKey.column1: "ستون ۱",
    _UiTextKey.column2: "ستون ۲",
    _UiTextKey.column3: "ستون ۳",
    _UiTextKey.addRow: "افزودن ردیف",
    _UiTextKey.searchEllipsis: "جستجو…",
    _UiTextKey.somethingWentWrong: "مشکلی پیش آمد",
    _UiTextKey.retry: "تلاش مجدد",
    _UiTextKey.string: "رشته",
    _UiTextKey.integer: "عدد صحیح",
    _UiTextKey.float: "اعشاری",
    _UiTextKey.boolean: "بولی",
    _UiTextKey.date: "تاریخ",
    _UiTextKey.dateTime: "تاریخ و زمان",
    _UiTextKey.file: "فایل",
    _UiTextKey.reference: "ارجاع",
    _UiTextKey.textField: "متن",
    _UiTextKey.number: "عدد",
    _UiTextKey.textArea: "ناحیه متن",
    _UiTextKey.dropdown: "فهرست کشویی",
    _UiTextKey.multiSelect: "چندانتخابی",
    _UiTextKey.checkbox: "چک‌باکس",
    _UiTextKey.radioGroup: "گروه رادیویی",
    _UiTextKey.datePicker: "انتخابگر تاریخ",
    _UiTextKey.timePicker: "انتخابگر زمان",
    _UiTextKey.fileUpload: "بارگذاری فایل",
    _UiTextKey.imageUpload: "بارگذاری تصویر",
    _UiTextKey.colorPicker: "انتخابگر رنگ",
    _UiTextKey.switchText: "سوئیچ",
    _UiTextKey.table: "جدول",
    _UiTextKey.rating: "امتیاز",
    _UiTextKey.signature: "امضا",
    _UiTextKey.medium: "متوسط",
    _UiTextKey.there: "there",
    _UiTextKey.emptyJsonObject: "{}",
    _UiTextKey.bulletSeparator: " · ",
    _UiTextKey.requiredAsterisk: "*",
    _UiTextKey.schemaSeparator: ",\n",
  };

  static String get exception => _text(_UiTextKey.exception);
  static String get autocreat => _text(_UiTextKey.autocreat);
  static String get createYourAccount => _text(_UiTextKey.createYourAccount);
  static String get startBuildingYourOrganizationalSystem =>
      _text(_UiTextKey.startBuildingYourOrganizationalSystem);
  static String get firstName => _text(_UiTextKey.firstName);
  static String get requiredText => _text(_UiTextKey.requiredText);
  static String get lastName => _text(_UiTextKey.lastName);
  static String get emailAddress => _text(_UiTextKey.emailAddress);
  static String get emailIsRequired => _text(_UiTextKey.emailIsRequired);
  static String get invalidEmail => _text(_UiTextKey.invalidEmail);
  static String get companyNameOptional =>
      _text(_UiTextKey.companyNameOptional);
  static String get password => _text(_UiTextKey.password);
  static String get passwordIsRequired => _text(_UiTextKey.passwordIsRequired);
  static String get atLeast8Characters => _text(_UiTextKey.atLeast8Characters);
  static String get confirmPassword => _text(_UiTextKey.confirmPassword);
  static String get passwordsDoNotMatch =>
      _text(_UiTextKey.passwordsDoNotMatch);
  static String get createAccount => _text(_UiTextKey.createAccount);
  static String get alreadyHaveAnAccount =>
      _text(_UiTextKey.alreadyHaveAnAccount);
  static String get signIn => _text(_UiTextKey.signIn);
  static String get demo123 => _text(_UiTextKey.demo123);
  static String get demo => _text(_UiTextKey.demo);
  static String get admin => _text(_UiTextKey.admin);
  static String get welcomeBack => _text(_UiTextKey.welcomeBack);
  static String get signInToYourOrganizationAccount =>
      _text(_UiTextKey.signInToYourOrganizationAccount);
  static String get passwordTooShort => _text(_UiTextKey.passwordTooShort);
  static String get forgotPassword => _text(_UiTextKey.forgotPassword);
  static String get signIn3 => _text(_UiTextKey.signIn3);
  static String get donTHaveAnAccount => _text(_UiTextKey.donTHaveAnAccount);
  static String get createAccount3 => _text(_UiTextKey.createAccount3);
  static String get demo3 => _text(_UiTextKey.demo3);
  static String get tryDemoMode => _text(_UiTextKey.tryDemoMode);
  static String get noAccountNeededExploreWithSampleData =>
      _text(_UiTextKey.noAccountNeededExploreWithSampleData);
  static String get organizationalSystemBuilder =>
      _text(_UiTextKey.organizationalSystemBuilder);
  static String get designComplexOrganizationalFlows =>
      _text(_UiTextKey.designComplexOrganizationalFlows);
  static String get buildFormsAndDataModels =>
      _text(_UiTextKey.buildFormsAndDataModels);
  static String get manageRolesAndPermissions =>
      _text(_UiTextKey.manageRolesAndPermissions);
  static String get communicateViaTickets =>
      _text(_UiTextKey.communicateViaTickets);
  static String get flowSaved => _text(_UiTextKey.flowSaved);
  static String get editNodeLabel => _text(_UiTextKey.editNodeLabel);
  static String get label => _text(_UiTextKey.label);
  static String get cancel => _text(_UiTextKey.cancel);
  static String get save => _text(_UiTextKey.save);
  static String get canvasControls => _text(_UiTextKey.canvasControls);
  static String get zoomOut => _text(_UiTextKey.zoomOut);
  static String get zoomIn => _text(_UiTextKey.zoomIn);
  static String get fitScreen => _text(_UiTextKey.fitScreen);
  static String get autoLayout => _text(_UiTextKey.autoLayout);
  static String get flowEditor => _text(_UiTextKey.flowEditor);
  static String get unsaved => _text(_UiTextKey.unsaved);
  static String get zoomOut3 => _text(_UiTextKey.zoomOut3);
  static String get zoomIn3 => _text(_UiTextKey.zoomIn3);
  static String get canvasControls3 => _text(_UiTextKey.canvasControls3);
  static String get saveFlow => _text(_UiTextKey.saveFlow);
  static String get addStartNode => _text(_UiTextKey.addStartNode);
  static String get addStepNode => _text(_UiTextKey.addStepNode);
  static String get addDecisionNode => _text(_UiTextKey.addDecisionNode);
  static String get addEndNode => _text(_UiTextKey.addEndNode);
  static String get fitToScreen => _text(_UiTextKey.fitToScreen);
  static String get nodeProperties => _text(_UiTextKey.nodeProperties);
  static String get deleteNode => _text(_UiTextKey.deleteNode);
  static String get close => _text(_UiTextKey.close);
  static String get startBuildingYourFlow =>
      _text(_UiTextKey.startBuildingYourFlow);
  static String get tapHereToAddAStartNodeNorUseTheToolbarOnTheLeft =>
      _text(_UiTextKey.tapHereToAddAStartNodeNorUseTheToolbarOnTheLeft);
  static String get newFlow => _text(_UiTextKey.newFlow);
  static String get start => _text(_UiTextKey.start);
  static String get end => _text(_UiTextKey.end);
  static String get automationFlows => _text(_UiTextKey.automationFlows);
  static String
      get designReviewAndLaunchOrganizationalProcessFlowsWithClearStep =>
          _text(_UiTextKey
              .designReviewAndLaunchOrganizationalProcessFlowsWithClearStep);
  static String get newText => _text(_UiTextKey.newText);
  static String get searchFlows => _text(_UiTextKey.searchFlows);
  static String get noFlowsYet => _text(_UiTextKey.noFlowsYet);
  static String get createYourFirstOrganizationalFlow =>
      _text(_UiTextKey.createYourFirstOrganizationalFlow);
  static String get createFlow => _text(_UiTextKey.createFlow);
  static String get deleteFlow => _text(_UiTextKey.deleteFlow);
  static String get thisWillDeleteTheFlowPermanently =>
      _text(_UiTextKey.thisWillDeleteTheFlowPermanently);
  static String get totalFlows => _text(_UiTextKey.totalFlows);
  static String get active => _text(_UiTextKey.active);
  static String get draft => _text(_UiTextKey.draft);
  static String get totalNodes => _text(_UiTextKey.totalNodes);
  static String get flowComplexity => _text(_UiTextKey.flowComplexity);
  static String get nodesAndEdgesPerFlow =>
      _text(_UiTextKey.nodesAndEdgesPerFlow);
  static String get nodeTypes => _text(_UiTextKey.nodeTypes);
  static String get openEditor => _text(_UiTextKey.openEditor);
  static String get delete => _text(_UiTextKey.delete);
  static String get nodeLabel => _text(_UiTextKey.nodeLabel);
  static String get enterLabelEllipsis => _text(_UiTextKey.enterLabelEllipsis);
  static String get description => _text(_UiTextKey.description);
  static String get optionalDescriptionEllipsis =>
      _text(_UiTextKey.optionalDescriptionEllipsis);
  static String get assignedRole => _text(_UiTextKey.assignedRole);
  static String get errorLoadingRoles => _text(_UiTextKey.errorLoadingRoles);
  static String get noRoleAssigned => _text(_UiTextKey.noRoleAssigned);
  static String get selectRoleEllipsis => _text(_UiTextKey.selectRoleEllipsis);
  static String get assignedForm => _text(_UiTextKey.assignedForm);
  static String get errorLoadingForms => _text(_UiTextKey.errorLoadingForms);
  static String get noFormAssigned => _text(_UiTextKey.noFormAssigned);
  static String get selectFormEllipsis => _text(_UiTextKey.selectFormEllipsis);
  static String get branches => _text(_UiTextKey.branches);
  static String get addBranch => _text(_UiTextKey.addBranch);
  static String get defaultText => _text(_UiTextKey.defaultText);
  static String get conditionEGStatusApproved =>
      _text(_UiTextKey.conditionEGStatusApproved);
  static String get position => _text(_UiTextKey.position);
  static String get capacity => _text(_UiTextKey.capacity);
  static String get members => _text(_UiTextKey.members);
  static String get flows => _text(_UiTextKey.flows);
  static String get details => _text(_UiTextKey.details);
  static String get website => _text(_UiTextKey.website);
  static String get created => _text(_UiTextKey.created);
  static String get text => _text(_UiTextKey.text);
  static String get companies => _text(_UiTextKey.companies);
  static String
      get organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK =>
          _text(_UiTextKey
              .organizeClientAndPartnerWorkspacesMonitorPortfolioHealthAndK);
  static String get newCompany => _text(_UiTextKey.newCompany);
  static String get searchCompanies => _text(_UiTextKey.searchCompanies);
  static String get noCompaniesYet => _text(_UiTextKey.noCompaniesYet);
  static String get noResultsFound => _text(_UiTextKey.noResultsFound);
  static String get createYourFirstCompanyToGetStarted =>
      _text(_UiTextKey.createYourFirstCompanyToGetStarted);
  static String get createCompany => _text(_UiTextKey.createCompany);
  static String get deleteCompany => _text(_UiTextKey.deleteCompany);
  static String get areYouSureYouWantToDeleteThisCompany =>
      _text(_UiTextKey.areYouSureYouWantToDeleteThisCompany);
  static String get edit => _text(_UiTextKey.edit);
  static String get editCompany => _text(_UiTextKey.editCompany);
  static String get companyNameRequired =>
      _text(_UiTextKey.companyNameRequired);
  static String get nameIsRequired => _text(_UiTextKey.nameIsRequired);
  static String get industry => _text(_UiTextKey.industry);
  static String get formSaved => _text(_UiTextKey.formSaved);
  static String get formEditor => _text(_UiTextKey.formEditor);
  static String get fieldTypes => _text(_UiTextKey.fieldTypes);
  static String get formName => _text(_UiTextKey.formName);
  static String get clickAFieldTypeToAddIt =>
      _text(_UiTextKey.clickAFieldTypeToAddIt);
  static String get requiredText3 => _text(_UiTextKey.requiredText3);
  static String get fieldProperties => _text(_UiTextKey.fieldProperties);
  static String get placeholder => _text(_UiTextKey.placeholder);
  static String get helpText => _text(_UiTextKey.helpText);
  static String get readOnly => _text(_UiTextKey.readOnly);
  static String get hidden => _text(_UiTextKey.hidden);
  static String get options => _text(_UiTextKey.options);
  static String get add => _text(_UiTextKey.add);
  static String get newForm => _text(_UiTextKey.newForm);
  static String get formDefinitions => _text(_UiTextKey.formDefinitions);
  static String
      get buildStructuredFormsThatCaptureReliableDataGuideUsersBeautif =>
          _text(_UiTextKey
              .buildStructuredFormsThatCaptureReliableDataGuideUsersBeautif);
  static String get searchForms => _text(_UiTextKey.searchForms);
  static String get noFormsYet => _text(_UiTextKey.noFormsYet);
  static String get createYourFirstFormDefinition =>
      _text(_UiTextKey.createYourFirstFormDefinition);
  static String get createForm => _text(_UiTextKey.createForm);
  static String get deleteForm => _text(_UiTextKey.deleteForm);
  static String get thisWillDeleteTheFormPermanently =>
      _text(_UiTextKey.thisWillDeleteTheFormPermanently);
  static String get totalForms => _text(_UiTextKey.totalForms);
  static String get totalFields => _text(_UiTextKey.totalFields);
  static String get fieldTypesDistribution =>
      _text(_UiTextKey.fieldTypesDistribution);
  static String get countOfEachFieldTypeAcrossAllForms =>
      _text(_UiTextKey.countOfEachFieldTypeAcrossAllForms);
  static String get noFieldsDefined => _text(_UiTextKey.noFieldsDefined);
  static String get userSaved => _text(_UiTextKey.userSaved);
  static String get newUser => _text(_UiTextKey.newUser);
  static String get editUser => _text(_UiTextKey.editUser);
  static String get changePhoto => _text(_UiTextKey.changePhoto);
  static String get uploadPhoto => _text(_UiTextKey.uploadPhoto);
  static String get userInfo => _text(_UiTextKey.userInfo);
  static String get firstNameRequired => _text(_UiTextKey.firstNameRequired);
  static String get lastNameRequired => _text(_UiTextKey.lastNameRequired);
  static String get emailRequired => _text(_UiTextKey.emailRequired);
  static String get phone => _text(_UiTextKey.phone);
  static String get passwordRequired => _text(_UiTextKey.passwordRequired);
  static String get newPasswordLeaveBlankToKeep =>
      _text(_UiTextKey.newPasswordLeaveBlankToKeep);
  static String get access => _text(_UiTextKey.access);
  static String get noRole => _text(_UiTextKey.noRole);
  static String get assignedRole3 => _text(_UiTextKey.assignedRole3);
  static String get activeAccount => _text(_UiTextKey.activeAccount);
  static String get inactiveUsersCannotLogIn =>
      _text(_UiTextKey.inactiveUsersCannotLogIn);
  static String get all => _text(_UiTextKey.all);
  static String get teamMembers => _text(_UiTextKey.teamMembers);
  static String
      get inviteTeammatesUnderstandAccountActivityAndBalanceRolesSoCol =>
          _text(_UiTextKey
              .inviteTeammatesUnderstandAccountActivityAndBalanceRolesSoCol);
  static String get addUser => _text(_UiTextKey.addUser);
  static String get searchMembers => _text(_UiTextKey.searchMembers);
  static String get noMembersFound => _text(_UiTextKey.noMembersFound);
  static String get tryAdjustingYourSearchOrFilters =>
      _text(_UiTextKey.tryAdjustingYourSearchOrFilters);
  static String get removeUser => _text(_UiTextKey.removeUser);
  static String get removeThisUserFromTheSystem =>
      _text(_UiTextKey.removeThisUserFromTheSystem);
  static String get totalMembers => _text(_UiTextKey.totalMembers);
  static String get admins => _text(_UiTextKey.admins);
  static String get roleDistribution => _text(_UiTextKey.roleDistribution);
  static String get membersByAssignedRole =>
      _text(_UiTextKey.membersByAssignedRole);
  static String get statusOverview => _text(_UiTextKey.statusOverview);
  static String get accountActivity => _text(_UiTextKey.accountActivity);
  static String get inactive => _text(_UiTextKey.inactive);
  static String get remove => _text(_UiTextKey.remove);
  static String get roleSaved => _text(_UiTextKey.roleSaved);
  static String get newRole => _text(_UiTextKey.newRole);
  static String get editRole => _text(_UiTextKey.editRole);
  static String get roleDetails => _text(_UiTextKey.roleDetails);
  static String get roleNameRequired => _text(_UiTextKey.roleNameRequired);
  static String get owner => _text(_UiTextKey.owner);
  static String get manager => _text(_UiTextKey.manager);
  static String get member => _text(_UiTextKey.member);
  static String get viewer => _text(_UiTextKey.viewer);
  static String get accessLevel => _text(_UiTextKey.accessLevel);
  static String get permissionCoverage => _text(_UiTextKey.permissionCoverage);
  static String get permissions => _text(_UiTextKey.permissions);
  static String get configureCrudPermissionsPerResource =>
      _text(_UiTextKey.configureCrudPermissionsPerResource);
  static String get resource => _text(_UiTextKey.resource);
  static String get create => _text(_UiTextKey.create);
  static String get read => _text(_UiTextKey.read);
  static String get update => _text(_UiTextKey.update);
  static String get rolesPermissions => _text(_UiTextKey.rolesPermissions);
  static String
      get shapeSecureAccessPoliciesClarifyResponsibilitiesAndGiveEvery =>
          _text(_UiTextKey
              .shapeSecureAccessPoliciesClarifyResponsibilitiesAndGiveEvery);
  static String get searchRoles => _text(_UiTextKey.searchRoles);
  static String get noRolesYet => _text(_UiTextKey.noRolesYet);
  static String get createRolesToManageAccessControl =>
      _text(_UiTextKey.createRolesToManageAccessControl);
  static String get createRole => _text(_UiTextKey.createRole);
  static String get deleteRole => _text(_UiTextKey.deleteRole);
  static String get deleteThisRolePermanently =>
      _text(_UiTextKey.deleteThisRolePermanently);
  static String get totalRoles => _text(_UiTextKey.totalRoles);
  static String get permissionSets => _text(_UiTextKey.permissionSets);
  static String get membersPerRole => _text(_UiTextKey.membersPerRole);
  static String get howManyUsersAreAssignedToEachRole =>
      _text(_UiTextKey.howManyUsersAreAssignedToEachRole);
  static String get open => _text(_UiTextKey.open);
  static String get inProgress => _text(_UiTextKey.inProgress);
  static String get resolved => _text(_UiTextKey.resolved);
  static String get closed => _text(_UiTextKey.closed);
  static String get supportTickets => _text(_UiTextKey.supportTickets);
  static String
      get trackCustomerRequestsPrioritizeUrgentWorkAndKeepEveryResolut =>
          _text(_UiTextKey
              .trackCustomerRequestsPrioritizeUrgentWorkAndKeepEveryResolut);
  static String get newTicket => _text(_UiTextKey.newTicket);
  static String get searchTickets => _text(_UiTextKey.searchTickets);
  static String get noTicketsFound => _text(_UiTextKey.noTicketsFound);
  static String get tryAdjustingYourFilters =>
      _text(_UiTextKey.tryAdjustingYourFilters);
  static String get total => _text(_UiTextKey.total);
  static String get low => _text(_UiTextKey.low);
  static String get med => _text(_UiTextKey.med);
  static String get high => _text(_UiTextKey.high);
  static String get urgent => _text(_UiTextKey.urgent);
  static String get priorityBreakdown => _text(_UiTextKey.priorityBreakdown);
  static String get ticketsByPriorityLevel =>
      _text(_UiTextKey.ticketsByPriorityLevel);
  static String get statusDistribution => _text(_UiTextKey.statusDistribution);
  static String get currentTicketStates =>
      _text(_UiTextKey.currentTicketStates);
  static String get noData => _text(_UiTextKey.noData);
  static String get dueToday => _text(_UiTextKey.dueToday);
  static String get titleRequired => _text(_UiTextKey.titleRequired);
  static String get titleIsRequired => _text(_UiTextKey.titleIsRequired);
  static String get priority => _text(_UiTextKey.priority);
  static String get attachment => _text(_UiTextKey.attachment);
  static String get ticketMessageSent => _text(_UiTextKey.ticketMessageSent);
  static String get ticketid => _text(_UiTextKey.ticketid);
  static String get noMessagesYet => _text(_UiTextKey.noMessagesYet);
  static String get attachFile => _text(_UiTextKey.attachFile);
  static String get typeAMessage => _text(_UiTextKey.typeAMessage);
  static String get ticketDetails => _text(_UiTextKey.ticketDetails);
  static String get status => _text(_UiTextKey.status);
  static String get creator => _text(_UiTextKey.creator);
  static String get assignee => _text(_UiTextKey.assignee);
  static String get dueDate => _text(_UiTextKey.dueDate);
  static String get slaProgress => _text(_UiTextKey.slaProgress);
  static String get tags => _text(_UiTextKey.tags);
  static String get deltacontent => _text(_UiTextKey.deltacontent);
  static String get templateSaved => _text(_UiTextKey.templateSaved);
  static String get templateName => _text(_UiTextKey.templateName);
  static String get attach => _text(_UiTextKey.attach);
  static String get variables => _text(_UiTextKey.variables);
  static String get addMore => _text(_UiTextKey.addMore);
  static String get startWritingYourLetterTemplate =>
      _text(_UiTextKey.startWritingYourLetterTemplate);
  static String get availableVariables => _text(_UiTextKey.availableVariables);
  static String
      get useTheseVariablesInYourTemplateTheyWillBeReplacedWithActualV =>
          _text(_UiTextKey
              .useTheseVariablesInYourTemplateTheyWillBeReplacedWithActualV);
  static String get userSFullName => _text(_UiTextKey.userSFullName);
  static String get userSEmail => _text(_UiTextKey.userSEmail);
  static String get companyName => _text(_UiTextKey.companyName);
  static String get currentDate => _text(_UiTextKey.currentDate);
  static String get flowName => _text(_UiTextKey.flowName);
  static String get newLetterTemplate => _text(_UiTextKey.newLetterTemplate);
  static String get uncategorized => _text(_UiTextKey.uncategorized);
  static String get letterTemplates => _text(_UiTextKey.letterTemplates);
  static String
      get manageReusableLetterTemplatesWithDynamicVariablesReadyToSend =>
          _text(_UiTextKey
              .manageReusableLetterTemplatesWithDynamicVariablesReadyToSend);
  static String get newTemplate => _text(_UiTextKey.newTemplate);
  static String get searchTemplates => _text(_UiTextKey.searchTemplates);
  static String get noLetterTemplates => _text(_UiTextKey.noLetterTemplates);
  static String get createReusableLetterTemplates =>
      _text(_UiTextKey.createReusableLetterTemplates);
  static String get createTemplate => _text(_UiTextKey.createTemplate);
  static String get deleteTemplate => _text(_UiTextKey.deleteTemplate);
  static String get deleteThisLetterTemplatePermanently =>
      _text(_UiTextKey.deleteThisLetterTemplatePermanently);
  static String get totalTemplates => _text(_UiTextKey.totalTemplates);
  static String get totalVariables => _text(_UiTextKey.totalVariables);
  static String get templatesByCategory =>
      _text(_UiTextKey.templatesByCategory);
  static String get distributionAcrossCategories =>
      _text(_UiTextKey.distributionAcrossCategories);
  static String get allCategories => _text(_UiTextKey.allCategories);
  static String get goodMorning => _text(_UiTextKey.goodMorning);
  static String get goodAfternoon => _text(_UiTextKey.goodAfternoon);
  static String get goodEvening => _text(_UiTextKey.goodEvening);
  static String get mon => _text(_UiTextKey.mon);
  static String get tue => _text(_UiTextKey.tue);
  static String get wed => _text(_UiTextKey.wed);
  static String get thu => _text(_UiTextKey.thu);
  static String get fri => _text(_UiTextKey.fri);
  static String get sat => _text(_UiTextKey.sat);
  static String get sun => _text(_UiTextKey.sun);
  static String get jan => _text(_UiTextKey.jan);
  static String get feb => _text(_UiTextKey.feb);
  static String get mar => _text(_UiTextKey.mar);
  static String get apr => _text(_UiTextKey.apr);
  static String get may => _text(_UiTextKey.may);
  static String get jun => _text(_UiTextKey.jun);
  static String get jul => _text(_UiTextKey.jul);
  static String get aug => _text(_UiTextKey.aug);
  static String get sep => _text(_UiTextKey.sep);
  static String get oct => _text(_UiTextKey.oct);
  static String get nov => _text(_UiTextKey.nov);
  static String get dec => _text(_UiTextKey.dec);
  static String get hereSWhatSHappeningInYourOrganizationToday =>
      _text(_UiTextKey.hereSWhatSHappeningInYourOrganizationToday);
  static String get activeOrganizations =>
      _text(_UiTextKey.activeOrganizations);
  static String get activeFlows => _text(_UiTextKey.activeFlows);
  static String get automationPipelines =>
      _text(_UiTextKey.automationPipelines);
  static String get openTickets => _text(_UiTextKey.openTickets);
  static String get needsAttention => _text(_UiTextKey.needsAttention);
  static String get closedTickets => _text(_UiTextKey.closedTickets);
  static String get activityOverview => _text(_UiTextKey.activityOverview);
  static String get ticketsFlowsLast7Days =>
      _text(_UiTextKey.ticketsFlowsLast7Days);
  static String get tickets => _text(_UiTextKey.tickets);
  static String get ticketStatus => _text(_UiTextKey.ticketStatus);
  static String get distributionOverview =>
      _text(_UiTextKey.distributionOverview);
  static String get noTicketsYet => _text(_UiTextKey.noTicketsYet);
  static String get recentTickets => _text(_UiTextKey.recentTickets);
  static String get latestActivity => _text(_UiTextKey.latestActivity);
  static String get viewAll => _text(_UiTextKey.viewAll);
  static String get resolutionRate => _text(_UiTextKey.resolutionRate);
  static String get slaCompliance => _text(_UiTextKey.slaCompliance);
  static String get performanceMetrics => _text(_UiTextKey.performanceMetrics);
  static String get ticketKpisAtAGlance =>
      _text(_UiTextKey.ticketKpisAtAGlance);
  static String get quickActions => _text(_UiTextKey.quickActions);
  static String get modelSaved => _text(_UiTextKey.modelSaved);
  static String get modelEditor => _text(_UiTextKey.modelEditor);
  static String get modelInfo => _text(_UiTextKey.modelInfo);
  static String get modelNameRequired => _text(_UiTextKey.modelNameRequired);
  static String get addField => _text(_UiTextKey.addField);
  static String get noFieldsYetAddYourFirstField =>
      _text(_UiTextKey.noFieldsYetAddYourFirstField);
  static String get jsonSchemaPreview => _text(_UiTextKey.jsonSchemaPreview);
  static String get text3 => _text(_UiTextKey.text3);
  static String get unique => _text(_UiTextKey.unique);
  static String get unique3 => _text(_UiTextKey.unique3);
  static String get fieldNameRequired => _text(_UiTextKey.fieldNameRequired);
  static String get fieldType => _text(_UiTextKey.fieldType);
  static String get newModel => _text(_UiTextKey.newModel);
  static String get dataModels => _text(_UiTextKey.dataModels);
  static String
      get defineDurableEntitySchemasOrganizeFieldsAndKeepYourOperation =>
          _text(_UiTextKey
              .defineDurableEntitySchemasOrganizeFieldsAndKeepYourOperation);
  static String get searchModels => _text(_UiTextKey.searchModels);
  static String get noModelsYet => _text(_UiTextKey.noModelsYet);
  static String get defineYourDataStructures =>
      _text(_UiTextKey.defineYourDataStructures);
  static String get createModel => _text(_UiTextKey.createModel);
  static String get deleteModel => _text(_UiTextKey.deleteModel);
  static String get deleteThisModelPermanently =>
      _text(_UiTextKey.deleteThisModelPermanently);
  static String get totalModels => _text(_UiTextKey.totalModels);
  static String get fieldTypeDistribution =>
      _text(_UiTextKey.fieldTypeDistribution);
  static String get breakdownOfFieldTypesAcrossAllModels =>
      _text(_UiTextKey.breakdownOfFieldTypesAcrossAllModels);
  static String get editLabel => _text(_UiTextKey.editLabel);
  static String get deleteEdge => _text(_UiTextKey.deleteEdge);
  static String get yes => _text(_UiTextKey.yes);
  static String get no => _text(_UiTextKey.no);
  static String get form => _text(_UiTextKey.form);
  static String get role => _text(_UiTextKey.role);
  static String get y => _text(_UiTextKey.y);
  static String get n3 => _text(_UiTextKey.n3);
  static String get ellipsis => _text(_UiTextKey.ellipsis);
  static String get noNodes => _text(_UiTextKey.noNodes);
  static String get dashboard => _text(_UiTextKey.dashboard);
  static String get overview => _text(_UiTextKey.overview);
  static String get organization => _text(_UiTextKey.organization);
  static String get users => _text(_UiTextKey.users);
  static String get roles => _text(_UiTextKey.roles);
  static String get automation => _text(_UiTextKey.automation);
  static String get forms => _text(_UiTextKey.forms);
  static String get models => _text(_UiTextKey.models);
  static String get letters => _text(_UiTextKey.letters);
  static String get communication => _text(_UiTextKey.communication);
  static String get menu => _text(_UiTextKey.menu);
  static String get search => _text(_UiTextKey.search);
  static String get notifications => _text(_UiTextKey.notifications);
  static String get toggleTheme => _text(_UiTextKey.toggleTheme);
  static String get search3 => _text(_UiTextKey.search3);
  static String get disableGlassMode => _text(_UiTextKey.disableGlassMode);
  static String get enableGlassMode => _text(_UiTextKey.enableGlassMode);
  static String get logout => _text(_UiTextKey.logout);
  static String get signOut => _text(_UiTextKey.signOut);
  static String get select => _text(_UiTextKey.select);
  static String get selectDate => _text(_UiTextKey.selectDate);
  static String get selectTime => _text(_UiTextKey.selectTime);
  static String get clickToUploadFile => _text(_UiTextKey.clickToUploadFile);
  static String get anyFileTypeSupported =>
      _text(_UiTextKey.anyFileTypeSupported);
  static String get clickToUploadImage => _text(_UiTextKey.clickToUploadImage);
  static String get pngJpgGifSupported => _text(_UiTextKey.pngJpgGifSupported);
  static String get pickAColor => _text(_UiTextKey.pickAColor);
  static String get done => _text(_UiTextKey.done);
  static String get signHere => _text(_UiTextKey.signHere);
  static String get column1 => _text(_UiTextKey.column1);
  static String get column2 => _text(_UiTextKey.column2);
  static String get column3 => _text(_UiTextKey.column3);
  static String get addRow => _text(_UiTextKey.addRow);
  static String get searchEllipsis => _text(_UiTextKey.searchEllipsis);
  static String get somethingWentWrong => _text(_UiTextKey.somethingWentWrong);
  static String get retry => _text(_UiTextKey.retry);
  static String get string => _text(_UiTextKey.string);
  static String get integer => _text(_UiTextKey.integer);
  static String get float => _text(_UiTextKey.float);
  static String get boolean => _text(_UiTextKey.boolean);
  static String get date => _text(_UiTextKey.date);
  static String get dateTime => _text(_UiTextKey.dateTime);
  static String get file => _text(_UiTextKey.file);
  static String get reference => _text(_UiTextKey.reference);
  static String get textField => _text(_UiTextKey.textField);
  static String get number => _text(_UiTextKey.number);
  static String get textArea => _text(_UiTextKey.textArea);
  static String get dropdown => _text(_UiTextKey.dropdown);
  static String get multiSelect => _text(_UiTextKey.multiSelect);
  static String get checkbox => _text(_UiTextKey.checkbox);
  static String get radioGroup => _text(_UiTextKey.radioGroup);
  static String get datePicker => _text(_UiTextKey.datePicker);
  static String get timePicker => _text(_UiTextKey.timePicker);
  static String get fileUpload => _text(_UiTextKey.fileUpload);
  static String get imageUpload => _text(_UiTextKey.imageUpload);
  static String get colorPicker => _text(_UiTextKey.colorPicker);
  static String get switchText => _text(_UiTextKey.switchText);
  static String get table => _text(_UiTextKey.table);
  static String get rating => _text(_UiTextKey.rating);
  static String get signature => _text(_UiTextKey.signature);
  static String get medium => _text(_UiTextKey.medium);
  static String get there => _text(_UiTextKey.there);
  static String get emptyJsonObject => _text(_UiTextKey.emptyJsonObject);
  static String get bulletSeparator => _text(_UiTextKey.bulletSeparator);
  static String get requiredAsterisk => _text(_UiTextKey.requiredAsterisk);
  static String get schemaSeparator => _text(_UiTextKey.schemaSeparator);

  static String languageToggleTooltip(AppLanguage nextLanguage) =>
      nextLanguage == AppLanguage.persian
          ? 'Switch to فارسی'
          : 'تغییر به English';

  static String exceptionMessage(Object? message) =>
      isPersian ? 'استثنا: ${message ?? ''}' : 'Exception: ${message ?? ''}';
  static String errorLoadingFlow(Object error) => isPersian
      ? 'خطا در بارگذاری جریان: $error'
      : 'Error loading flow: $error';
  static String errorSaving(Object error) =>
      isPersian ? 'خطا در ذخیره‌سازی: $error' : 'Error saving: $error';
  static String error(Object error) =>
      isPersian ? 'خطا: $error' : 'Error: $error';
  static String demoAccountLabel(String label) =>
      isPersian ? 'نمایشی: $label' : 'Demo: $label';
  static String zoomPercent(num scale) => isPersian
      ? 'بزرگ‌نمایی: ${(scale * 100).toInt()}٪'
      : 'Zoom: ${(scale * 100).toInt()}%';
  static String percent(num value) =>
      isPersian ? '${(value * 100).toInt()}٪' : '${(value * 100).toInt()}%';
  static String nodesAndEdges(int nodes, int edges) =>
      isPersian ? '$nodes گره · $edges یال' : '$nodes nodes · $edges edges';
  static String nodesCount(int nodes) =>
      isPersian ? '$nodes گره' : '$nodes nodes';
  static String edgesCount(int edges) =>
      isPersian ? '$edges یال' : '$edges edges';
  static String stepsCount(int steps) =>
      isPersian ? '$steps مرحله' : '$steps steps';
  static String decisionsCount(int decisions) =>
      isPersian ? '$decisions تصمیم' : '$decisions decisions';
  static String totalEdges(int totalEdges) =>
      isPersian ? 'کل $totalEdges یال' : '$totalEdges edges total';
  static String chartValue(String label, int value) => '$label: $value';
  static String branchName(int branchNumber) =>
      isPersian ? 'شاخه $branchNumber' : 'Branch $branchNumber';
  static String nodePosition(num x, num y) => isPersian
      ? 'x: ${x.toInt()}،  y: ${y.toInt()}'
      : 'x: ${x.toInt()},  y: ${y.toInt()}';
  static String capacityRatio(int count, int max) => '$count / $max';
  static String joined(String joined) =>
      isPersian ? 'پیوسته در $joined' : 'Joined $joined';
  static String fieldCount(int count) =>
      isPersian ? '$count فیلد' : '$count fields';
  static String requiredCount(int count) =>
      isPersian ? '$count الزامی' : '$count req';
  static String uniqueCount(int count) =>
      isPersian ? '$count یکتا' : '$count unique';
  static String moreCount(int count) =>
      isPersian ? '+$count مورد دیگر' : '+$count more';
  static String distributionSlice(Object label, Object value) =>
      '$label: $value';
  static String distributionLegend(Object value, Object percent) =>
      isPersian ? '$value ($percent٪)' : '$value ($percent%)';
  static String userInitials(String firstName, String lastName) =>
      '${firstName[0]}${lastName[0]}';
  static String initialsFromParts(String firstInitial, String lastInitial) =>
      '$firstInitial$lastInitial'.toUpperCase();
  static String rgbHex(int red, int green, int blue) =>
      '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
  static String userFullName(String firstName, String lastName) =>
      isPersian ? '$lastName $firstName' : '$firstName $lastName';
  static String greetingLine(String greeting, String firstName) =>
      isPersian ? '$greeting، $firstName!' : '$greeting, $firstName!';
  static String dateLine(String dayName, int day, String monthName, int year) =>
      isPersian
          ? '$dayName، $day $monthName $year'
          : '$dayName, $day $monthName $year';
  static String timeLine(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  static String truncatedName(String name) => '${name.substring(0, 9)}…';
  static String optionNumber(int optionNumber) =>
      isPersian ? 'گزینه $optionNumber' : 'Option $optionNumber';
  static String crudCoverage(num coverage) => isPersian
      ? '${(coverage * 100).toInt()}٪ از عملیات CRUD در همه منابع اعطا شده است.'
      : '${(coverage * 100).toInt()}% of CRUD operations are granted across all resources.';
  static String truncatedName7(String name) => '${name.substring(0, 7)}…';
  static String membersCount(int count) =>
      isPersian ? '$count عضو' : '$count members';
  static String resourcesCount(int count) =>
      isPersian ? '$count منبع' : '$count resources';
  static String canCreateCount(int count) =>
      isPersian ? '$count ایجاد' : '$count create';
  static String dueInDays(int days) =>
      isPersian ? 'سررسید تا $days روز' : 'Due in ${days}d';
  static String daysOverdue(int days) =>
      isPersian ? '$days روز تأخیر' : '${days}d overdue';
  static String priorityLabel(String priority) =>
      isPersian ? 'اولویت $priority' : '$priority priority';
  static String fileCount(int count) =>
      isPersian ? '$count فایل' : '$count file${count > 1 ? 's' : ''}';
  static String avgVars(String average) =>
      isPersian ? 'میانگین $average متغیر' : 'Avg $average vars';
  static String varsCount(int count) =>
      isPersian ? '$count متغیر' : '$count vars';
  static String fieldsTitle(int count) =>
      isPersian ? 'فیلدها ($count)' : 'Fields ($count)';
  static String schemaField(String name, String type, bool required) =>
      '  "$name": "$type"${required ? (isPersian ? ' (الزامی)' : ' (required)') : ''}';
  static String schemaObject(String fields) => '{\n$fields\n}';
}
