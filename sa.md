graph TD

ROOT["📦 Project Root"]

ROOT --> SRC["src"]
ROOT --> TOOLS["tools"]
ROOT --> DOCS["docs"]
ROOT --> E2E["e2e"]
ROOT --> SCRIPTS["scripts"]
ROOT --> CONFIG["Configuration Files"]

CONFIG --> ANGULAR["angular.json"]
CONFIG --> PACKAGE["package.json"]
CONFIG --> TSCONFIG["tsconfig.json"]
CONFIG --> ESLINT["eslint.config.js"]
CONFIG --> PRETTIER[".prettierrc"]
CONFIG --> EDITOR[".editorconfig"]
CONFIG --> GIT[".gitignore"]
CONFIG --> HUSKY[".husky"]

SRC --> MAIN["main.ts"]
SRC --> INDEX["index.html"]
SRC --> STYLES["styles.scss"]
SRC --> POLYFILLS["polyfills.ts"]
SRC --> APP["app"]
SRC --> ASSETS["assets"]
SRC --> ENV["environments"]

%% =======================================================
%% APP
%% =======================================================

APP --> CONFIGURATION["config"]
APP --> CORE["core"]
APP --> SHARED["shared"]
APP --> FEATURES["features"]
APP --> LAYOUTS["layouts"]
APP --> SHELL["shell"]
APP --> ROUTES["routes"]
APP --> GLOBALSTATE["state"]
APP --> APPCONFIG["app.config.ts"]
APP --> APPCOMPONENT["app.component.ts"]

%% =======================================================
%% CONFIG
%% =======================================================

CONFIGURATION --> APPSETTINGS["app.settings.ts"]
CONFIGURATION --> APICONFIG["api.config.ts"]
CONFIGURATION --> FEATUREFLAGS["feature-flags.ts"]
CONFIGURATION --> ENVCONFIG["environment.config.ts"]

%% =======================================================
%% CORE
%% =======================================================

CORE --> AUTH["authentication"]
CORE --> AUTHORIZATION["authorization"]
CORE --> INTERCEPTORS["interceptors"]
CORE --> GUARDS["guards"]
CORE --> RESOLVERS["resolvers"]
CORE --> ERRORHANDLER["error-handler"]
CORE --> LOGGER["logger"]
CORE --> CONFIGSERVICE["configuration"]
CORE --> HTTP["http"]
CORE --> TOKENS["tokens"]
CORE --> INIT["app-initializer"]
CORE --> STORAGE["storage"]
CORE --> ANALYTICS["analytics"]
CORE --> TELEMETRY["telemetry"]
CORE --> EXCEPTIONS["exceptions"]
CORE --> UTILS["utilities"]

AUTH --> LOGIN["login.service.ts"]
AUTH --> TOKEN["token.service.ts"]
AUTH --> REFRESH["refresh-token.service.ts"]
AUTH --> AUTHSTATE["auth-state.service.ts"]

INTERCEPTORS --> AUTHINT["auth.interceptor.ts"]
INTERCEPTORS --> ERRORINT["error.interceptor.ts"]
INTERCEPTORS --> LOADINGINT["loading.interceptor.ts"]
INTERCEPTORS --> CACHEINT["cache.interceptor.ts"]
INTERCEPTORS --> LOGINT["logging.interceptor.ts"]

GUARDS --> AUTHGUARD["auth.guard.ts"]
GUARDS --> ROLEGUARD["role.guard.ts"]
GUARDS --> PERMISSIONGUARD["permission.guard.ts"]

HTTP --> APIBASE["api-base.service.ts"]
HTTP --> HTTPCLIENT["http-client.ts"]

%% =======================================================
%% SHARED
%% =======================================================

SHARED --> UI["ui"]
SHARED --> COMPONENTS["components"]
SHARED --> DIRECTIVES["directives"]
SHARED --> PIPES["pipes"]
SHARED --> VALIDATORS["validators"]
SHARED --> HELPERS["helpers"]
SHARED --> CONSTANTS["constants"]
SHARED --> ENUMS["enums"]
SHARED --> TYPES["types"]
SHARED --> MODELS["models"]
SHARED --> UTILITIES["utilities"]
SHARED --> ICONS["icons"]

UI --> BUTTON["button"]
UI --> CARD["card"]
UI --> TABLE["table"]
UI --> MODAL["modal"]
UI --> DIALOG["dialog"]
UI --> SPINNER["spinner"]
UI --> DROPDOWN["dropdown"]
UI --> INPUT["input"]
UI --> FORMFIELD["form-field"]
UI --> DATEPICKER["date-picker"]
UI --> SIDENAV["side-nav"]
UI --> TOOLBAR["toolbar"]
UI --> BREADCRUMB["breadcrumb"]

BUTTON --> BUTTONTS["button.component.ts"]
BUTTON --> BUTTONHTML["button.component.html"]
BUTTON --> BUTTONSCSS["button.component.scss"]

DIRECTIVES --> AUTFOCUS["autofocus.directive.ts"]
DIRECTIVES --> PERMISSION["permission.directive.ts"]
DIRECTIVES --> DEBOUNCE["debounce-click.directive.ts"]

PIPES --> DATEPIPE["date.pipe.ts"]
PIPES --> FILESIZE["filesize.pipe.ts"]
PIPES --> SAFEHTML["safe-html.pipe.ts"]

%% =======================================================
%% FEATURES
%% =======================================================

FEATURES --> DASHBOARD["dashboard"]
FEATURES --> USERS["users"]
FEATURES --> REPORTS["reports"]
FEATURES --> SETTINGS["settings"]
FEATURES --> ANALYTICSF["analytics"]
FEATURES --> NOTIFICATIONS["notifications"]
FEATURES --> PROFILE["profile"]
FEATURES --> ADMIN["admin"]

%% USERS FEATURE

USERS --> USERPAGES["pages"]
USERS --> USERCOMPONENTS["components"]
USERS --> USERDIALOGS["dialogs"]
USERS --> USERAPI["api"]
USERS --> USERSERVICES["services"]
USERS --> USERSTORE["store"]
USERS --> USERMODELS["models"]
USERS --> USERMAPPERS["mappers"]
USERS --> USERUTILS["utils"]
USERS --> USERGUARDS["guards"]
USERS --> USERROUTES["users.routes.ts"]
USERS --> USERFACADE["users.facade.ts"]

USERPAGES --> USERLIST["user-list"]
USERPAGES --> USERDETAIL["user-detail"]
USERPAGES --> USEREDIT["user-edit"]
USERPAGES --> USERCREATE["create-user"]

USERLIST --> ULISTTS["user-list.component.ts"]
USERLIST --> ULISTHTML["user-list.component.html"]
USERLIST --> ULISTSCSS["user-list.component.scss"]
USERLIST --> ULISTSPEC["user-list.component.spec.ts"]

USERCOMPONENTS --> USERTABLE["user-table"]
USERCOMPONENTS --> USERCARD["user-card"]
USERCOMPONENTS --> USERFILTER["user-filter"]
USERCOMPONENTS --> USERHEADER["user-header"]
USERCOMPONENTS --> USERAVATAR["user-avatar"]

USERAPI --> USERSAPI["users.api.ts"]
USERAPI --> ROLESAPI["roles.api.ts"]
USERAPI --> PERMISSIONAPI["permissions.api.ts"]

USERSERVICES --> EXPORTSERVICE["export.service.ts"]
USERSERVICES --> FILTERSERVICE["filter.service.ts"]
USERSERVICES --> CACHESERVICE["cache.service.ts"]

USERSTORE --> ACTIONS["actions.ts"]
USERSTORE --> REDUCER["reducer.ts"]
USERSTORE --> EFFECTS["effects.ts"]
USERSTORE --> SELECTORS["selectors.ts"]
USERSTORE --> SIGNALSTORE["signal-store.ts"]

%% =======================================================
%% LAYOUTS
%% =======================================================

LAYOUTS --> ADMINLAYOUT["admin-layout"]
LAYOUTS --> PUBLICLAYOUT["public-layout"]
LAYOUTS --> AUTHLAYOUT["auth-layout"]
LAYOUTS --> BLANKLAYOUT["blank-layout"]

ADMINLAYOUT --> HEADER["header"]
ADMINLAYOUT --> SIDEBAR["sidebar"]
ADMINLAYOUT --> FOOTER["footer"]
ADMINLAYOUT --> TOPBAR["topbar"]

%% =======================================================
%% SHELL
%% =======================================================

SHELL --> APPSHELL["app-shell.component.ts"]
SHELL --> NAVIGATION["navigation.service.ts"]
SHELL --> MENU["menu.service.ts"]
SHELL --> BREADCRUMBS["breadcrumb.service.ts"]

%% =======================================================
%% ROUTES
%% =======================================================

ROUTES --> APPROUTES["app.routes.ts"]
ROUTES --> AUTHROUTES["auth.routes.ts"]
ROUTES --> ADMINROUTES["admin.routes.ts"]

%% =======================================================
%% GLOBAL STATE
%% =======================================================

GLOBALSTATE --> AUTHSTATE2["auth"]
GLOBALSTATE --> THEME["theme"]
GLOBALSTATE --> SETTINGSSTATE["settings"]
GLOBALSTATE --> NOTIFSTATE["notifications"]

AUTHSTATE2 --> AUTHACTION["actions.ts"]
AUTHSTATE2 --> AUTHSELECTOR["selectors.ts"]
AUTHSTATE2 --> AUTHREDUCER["reducer.ts"]
AUTHSTATE2 --> AUTHEFFECT["effects.ts"]

%% =======================================================
%% ASSETS
%% =======================================================

ASSETS --> IMAGES["images"]
ASSETS --> ICONSET["icons"]
ASSETS --> FONTS["fonts"]
ASSETS --> I18N["i18n"]
ASSETS --> ANIMATIONS["animations"]
ASSETS --> MOCKS["mock-data"]

%% =======================================================
%% ENVIRONMENTS
%% =======================================================

ENV --> DEV["environment.ts"]
ENV --> PROD["environment.prod.ts"]
ENV --> STAGING["environment.staging.ts"]
ENV --> QA["environment.qa.ts"]
ENV --> LOCAL["environment.local.ts"]
