# Sakura Application - Video Scripts for Stakeholders

**Purpose:** Training videos to help stakeholders understand how Sakura currently functions  
**Format:** 2-3 minute videos with natural narration and real-world examples  
**Total Videos:** 6

---

## 📹 Video 0: Admin - Workspace Management (2-3 minutes)

### Script

**[0:00-0:10] Introduction**

"Hi, I'm going to show you how to manage workspaces in Sakura as an administrator. Workspaces are the top-level containers that organize all your apps, reports, and security models. Let's start by navigating to the Workspace Management page."

**[PAUSE - 2 seconds]**

**[0:10-0:25] Navigation & Overview**

"You'll see three tabs at the top: Workspaces, List of Values, and Application Settings. We'll focus on the Workspaces tab today. On this page, you can see all workspaces in a table format with columns for name, code, owner, domain, tag, and status."

**[PAUSE - 2 seconds]**

**[0:25-0:45] Search & Filtering**

"Let's say you're looking for the Finance workspace. You can use the search bar to search by name, code, owner, or tag. For example, typing 'Finance' will filter the list. You also have advanced filters - you can filter by type, status, owner, or tag. The 'Active only' toggle lets you show just active workspaces or include inactive ones."

**[PAUSE - 2 seconds]**

**[0:45-1:15] Create Workspace**

"Now let's create a new workspace. Click the 'Create workspace' button. I'll create a workspace for the Marketing department. I'll enter the workspace code as 'MKT', the name as 'Marketing Workspace', and assign Jane Smith as the owner. I'll set John Doe as the technical owner, and Sarah Johnson as the approver. I'll select 'Business Operations' as the domain from the dropdown. Tags and Entra Group UID are optional. Now I'll click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"Perfect! The workspace has been created successfully and appears in the table."

**[PAUSE - 2 seconds]**

**[1:15-1:35] View Workspace Details**

"To see more details about a workspace, click the expand arrow on the left. This shows you the full information including owner, technical owner, approver, domain, tag, Entra Group UID, and how many apps are associated with this workspace. Click the arrow again to collapse it."

**[PAUSE - 2 seconds]**

**[1:35-2:00] Edit Workspace**

"To edit a workspace, click the edit icon in the Actions column. Let's say we need to update the Marketing workspace - maybe change the owner to Mary Williams. I'll update the owner field and click 'Save'."

**[PAUSE - 3 seconds - show success message]**

"The workspace has been updated successfully."

**[PAUSE - 2 seconds]**

**[2:00-2:20] Deactivate Workspace**

"If you need to temporarily disable a workspace, click the deactivate icon. A confirmation dialog will appear asking you to confirm. After confirming, the workspace status changes to 'Inactive' and it will be hidden from most views unless you toggle 'Show all'."

**[PAUSE - 2 seconds]**

**[2:20-2:35] Activate Workspace**

"To reactivate an inactive workspace, click the activate icon. The workspace will become active again and visible to workspace owners."

**[PAUSE - 2 seconds]**

**[2:35-2:50] Delete Workspace**

"Finally, to permanently delete a workspace, click the delete icon. This performs a soft delete - the workspace is marked as deleted but can be recovered if needed. Confirm the deletion in the dialog."

**[PAUSE - 2 seconds]**

**[2:50-3:00] Wrap-up**

"That covers workspace management for administrators. You can create, edit, view details, activate, deactivate, and delete workspaces. The other tabs - List of Values and Application Settings - are for system configuration and can be explored separately. Thanks for watching!"

---

## 📹 Video 1: Workspace Apps Management (2-3 minutes)

### Script

**[0:00-0:10] Introduction**

"Hi, in this video I'll show you how workspace owners manage apps within their workspace. Apps are the applications that users can request access to. Let's navigate to the WSO Console and select the Object Management section, then the Apps tab."

**[PAUSE - 2 seconds]**

**[0:10-0:25] Overview**

"Here you can see all apps for your workspace. The table shows app code, name, owner, technical owner, approval mode, OLS mode, number of audiences, status, and last modified date. You can search apps, filter by active status, and refresh the list."

**[PAUSE - 2 seconds]**

**[0:25-1:00] Create Workspace App**

"Let's create a new app. Click 'Add new app'. I'll create an app called 'Sales Analytics Dashboard'. First, I'll enter the app code as 'SALES-ANALYTICS' - note that codes must be uppercase. The app name is 'Sales Analytics Dashboard'. I'll set the app owner as sales.manager@dentsu.com and the technical owner as tech.support@dentsu.com."

**[PAUSE - 2 seconds]**

"Now for OLS Mode - I'll select 'Unmanaged' which means users manage their own access. If I selected 'Managed', I would need to provide an Entra Group UID. For Approval Mode, I'll choose 'AppBased' which means approvals happen at the app level. If I chose 'AudienceBased', approvals would happen at the audience level."

**[PAUSE - 2 seconds]**

"Since I selected AppBased approval mode, I need to add approvers. I'll add sales.director@dentsu.com and sales.vp@dentsu.com. These are the people who will approve access requests. Now I'll click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"Great! The app has been created and appears in the list."

**[PAUSE - 2 seconds]**

**[1:00-1:20] View App Details**

"To see full details about an app, click on the app name or use the Actions menu and select 'View Details'. This shows you all the configuration including approval mode, OLS mode, approvers, and how many audiences are linked to this app."

**[PAUSE - 2 seconds]**

**[1:20-1:45] Edit App**

"To edit an app, click the Actions menu - that's the three dots - and select 'Edit App'. Let's say we need to change the technical owner to a new support contact. I'll update the field and save. The app is updated with the latest information."

**[PAUSE - 2 seconds]**

**[1:45-2:05] Update Approvers**

"For apps with AppBased approval mode, you can update the approvers list. Click Actions, then 'Update Approvers'. I'll add another approver - regional.manager@dentsu.com - and remove one. Click 'Save' to update the approvers."

**[PAUSE - 3 seconds - show success message]**

"The approvers have been updated successfully."

**[PAUSE - 2 seconds]**

**[2:05-2:25] Activate/Deactivate App**

"To deactivate an app, use the Actions menu and toggle the status switch. A confirmation dialog appears. After confirming, the app status changes to 'Inactive' and users won't be able to request access. To reactivate, just toggle it back to 'Active'."

**[PAUSE - 2 seconds]**

**[2:25-2:40] Wrap-up**

"That's how you manage workspace apps. You can create apps, edit their details, update approvers for AppBased apps, view full details, and activate or deactivate them. In the next video, we'll cover managing audiences for these apps. Thanks for watching!"

---

## 📹 Video 2: App Audiences Management (2-3 minutes)

### Script

**[0:00-0:10] Introduction**

"Hi, in this video I'll show you how to manage app audiences. Audiences are groups of users who share access to reports through Power BI apps. Let's navigate to the WSO Console, Object Management, and select the Audiences tab."

**[PAUSE - 2 seconds]**

**[0:10-0:25] Overview**

"Here you can see all audiences for your workspace. The table shows the audience name, which app it belongs to, the owner, number of members, status, and last modified. You can search audiences, filter by active status, and see which workspace and app each audience belongs to."

**[PAUSE - 2 seconds]**

**[0:25-1:00] Create App Audience**

"Let's create a new audience. Click 'Add new audience'. I'll create an audience for the Finance team. First, I need to select which app this audience belongs to - let's choose 'Finance Dashboard' app. The audience name will be 'Finance Team'. I'll set the audience owner as finance.manager@dentsu.com - this person will also be the approver for access requests."

**[PAUSE - 2 seconds]**

"If this audience uses an Entra Group for membership, I can optionally add the Entra Group UID. For now, I'll leave it blank. Now I'll click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"Perfect! The audience has been created and is now linked to the Finance Dashboard app."

**[PAUSE - 2 seconds]**

**[1:00-1:20] View Audience Details**

"To see full details about an audience, click on the audience name or use the Actions menu and select 'View Details'. This shows you the parent app, owner, approvers, Entra Group UID if configured, and status information."

**[PAUSE - 2 seconds]**

**[1:20-1:45] Edit Audience**

"To edit an audience, click the Actions menu and select 'Edit Audience'. Let's say we need to change the owner to a new finance manager. I'll update the owner field and save. The audience information is updated."

**[PAUSE - 2 seconds]**

**[1:45-2:05] Update Audience Approvers**

"You can update the approvers for an audience. Click Actions, then 'Update Approvers'. I'll add finance.director@dentsu.com as an additional approver. Click 'Save'."

**[PAUSE - 3 seconds - show success message]**

"The approvers have been updated successfully."

**[PAUSE - 2 seconds]**

**[2:05-2:25] Activate/Deactivate Audience**

"To deactivate an audience, use the Actions menu and toggle the status switch. After confirming, the audience becomes inactive and users in that audience will lose access to associated reports. To reactivate, toggle it back to 'Active'."

**[PAUSE - 2 seconds]**

**[2:25-2:40] Wrap-up**

"That covers audience management. You can create audiences linked to apps, edit their details, update approvers, view full information, and activate or deactivate them. Audiences are important because they're used to grant access to AUR reports, which we'll cover in the next video. Thanks for watching!"

---

## 📹 Video 3: Workspace Reports - SAR vs AUR (2-3 minutes)

### Script

**[0:00-0:10] Introduction**

"Hi, in this video I'll explain the two types of reports in Sakura - SAR and AUR - and how to manage them. Let's navigate to the WSO Console, Object Management, and select the Reports tab."

**[PAUSE - 2 seconds]**

**[0:10-0:30] Understanding SAR vs AUR**

"First, let me explain the difference. SAR stands for Single Access Report - these are reports that users request individually, and each request needs approval. AUR stands for Audience Report - these are reports delivered through Power BI apps, and users get access automatically if they're members of a linked audience."

**[PAUSE - 3 seconds]**

**[0:30-1:10] Create SAR Report**

"Let's create a SAR report first. Click 'Add new report'. I'll create a report called 'Executive P&L Statement'. The report code will be 'EXEC-PL'. For Delivery Method, I'll select 'SAR - Single Access Report'. Since this is a SAR report, I MUST provide approvers - these are the people who will approve individual access requests. I'll add cfo@dentsu.com and finance.director@dentsu.com."

**[PAUSE - 2 seconds]**

"I'll set the report owner as finance.team@dentsu.com, add a tag like 'Executive', and optionally add keywords for searchability. Now I'll click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"The SAR report has been created. Notice that SAR reports do NOT get mapped to audiences - users request access individually."

**[PAUSE - 2 seconds]**

**[1:10-1:40] Create AUR Report**

"Now let's create an AUR report. I'll create 'Cash Flow Dashboard'. The report code is 'CASH-FLOW'. For Delivery Method, I'll select 'AUR - Audience Report'. For AUR reports, approvers are optional - I can leave this empty or add them. The important thing is that AUR reports MUST be mapped to audiences, which we'll do in the next video."

**[PAUSE - 2 seconds]**

"I'll set the owner, add a tag, and create the report."

**[PAUSE - 3 seconds - show success message]**

"The AUR report is created. Notice the difference - AUR reports will be linked to audiences, while SAR reports use individual approvals."

**[PAUSE - 2 seconds]**

**[1:40-2:00] Edit Report**

"To edit a report, click the Actions menu and select 'Edit Report'. You can change the report name, description, owner, tag, and even switch between SAR and AUR delivery methods. However, if you change from AUR to SAR, you'll need to add approvers. If you change from SAR to AUR, you'll need to remove approvers and add audience mappings instead."

**[PAUSE - 2 seconds]**

**[2:00-2:15] Update Report Approvers**

"For SAR reports, you can update the approvers list. Click Actions, then 'Update Approvers'. Add or remove approver emails and save."

**[PAUSE - 2 seconds]**

**[2:15-2:30] View Report Details**

"Click on a report name or use 'View Details' to see full information including delivery method, approvers, linked audiences for AUR reports, and linked security models."

**[PAUSE - 2 seconds]**

**[2:30-2:45] Activate/Deactivate Report**

"Use the Actions menu to toggle report status. Deactivated reports won't be available for access requests or audience access."

**[PAUSE - 2 seconds]**

**[2:45-3:00] Wrap-up**

"To summarize: SAR reports require approvers and individual user requests. AUR reports are linked to audiences for automatic access. In the next video, we'll show you how to create those audience and security model mappings. Thanks for watching!"

---

## 📹 Video 4: Report Mappings - Audiences & Security Models (2-3 minutes)

### Script

**[0:00-0:10] Introduction**

"Hi, in this video I'll show you how to create mappings between reports and audiences, and between reports and security models. These mappings control who can access reports and what data they see. Let's go to the WSO Console, Object Management, and select the Mappings tab."

**[PAUSE - 2 seconds]**

**[0:10-0:30] Understanding Mappings**

"There are three types of mappings here. First, Report-to-Audience mappings - these link AUR reports to audiences so users in those audiences get automatic access. Second, Report-to-Security Model mappings - these link reports to security models for Row-Level Security, controlling what data rows users can see. Third, Security Model-to-Security Type mappings, which we'll cover in the next video."

**[PAUSE - 3 seconds]**

**[0:30-1:10] Create Report-Audience Mapping**

"Let's create a Report-to-Audience mapping. This is only for AUR reports. I'll click 'Add Report-Audience Mapping'. First, I select an AUR report - let's choose 'Cash Flow Dashboard'. Then I select an audience to link - I'll choose 'Finance Team' audience. Click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"Perfect! Now all users who are members of the Finance Team audience will automatically have access to the Cash Flow Dashboard report. You can link one AUR report to multiple audiences - for example, I could also link it to 'Executive Leadership' audience."

**[PAUSE - 2 seconds]**

**[1:10-1:30] Delete Report-Audience Mapping**

"To remove a mapping, find it in the list and click the delete icon. Confirm the deletion. Users in that audience will lose access to the report."

**[PAUSE - 2 seconds]**

**[1:30-2:00] Create Report-Security Model Mapping**

"Now let's create a Report-to-Security Model mapping. This works for both SAR and AUR reports. Security models control Row-Level Security - what data rows users can see based on their department, region, or other criteria. I'll click 'Add Report-Security Model Mapping'. I'll select the 'P&L Statement' report and link it to the 'Department-Level Security' model. Click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"Now this report will use the Department-Level Security model to filter data. Users will only see rows that match their department assignment."

**[PAUSE - 2 seconds]**

**[2:00-2:15] Delete Report-Security Model Mapping**

"To remove a security model mapping, find it in the list and click delete. The report will no longer use that security model for data filtering."

**[PAUSE - 2 seconds]**

**[2:15-2:30] View Mappings**

"You can view all mappings in the table. For Report-Audience mappings, you'll see which AUR reports are linked to which audiences. For Report-Security Model mappings, you'll see which reports use which security models. You can search and filter these mappings."

**[PAUSE - 2 seconds]**

**[2:30-2:45] Wrap-up**

"To summarize: Report-Audience mappings link AUR reports to audiences for automatic access. Report-Security Model mappings link reports to security models for Row-Level Security. One report can have multiple mappings of each type. In the next video, we'll cover security models themselves. Thanks for watching!"

---

## 📹 Video 5: Security Models - CRUD & Security Types (2-3 minutes)

### Script

**[0:00-0:10] Introduction**

"Hi, in this final video I'll show you how to manage security models and their security type mappings. Security models define Row-Level Security rules that control what data users can see in reports. Let's navigate to the Security Models section in the WSO Console."

**[PAUSE - 2 seconds]**

**[0:10-0:30] Understanding Security Models**

"Security models are workspace-specific configurations that define how data is filtered. They're linked to security types - like Department, Region, or Cost Center - which determine the dimension of security. Security models are then mapped to reports to apply that filtering."

**[PAUSE - 3 seconds]**

**[0:30-1:00] Create Security Model**

"Let's create a new security model. Click 'Add Security Model'. I'll create a model called 'Regional Security Model'. The model code will be 'REGIONAL-SEC'. I'll add a description explaining this model filters data by region. Now I'll click 'Create'."

**[PAUSE - 3 seconds - show success message]**

"The security model has been created. Now I need to assign security types to it."

**[PAUSE - 2 seconds]**

**[1:00-1:30] Manage Security Types for Model**

"To assign security types, I'll click on the security model and then 'Manage Security Types'. Security types come from the List of Values - things like Department, Region, Cost Center, etc. I'll select 'Region' and 'Country' security types for this regional model. I can add multiple types at once using the bulk add option, or add them one by one."

**[PAUSE - 2 seconds]**

"Let me add 'Region' first, then 'Country'. I'll click 'Add' for each, or use 'Add All' if selecting multiple."

**[PAUSE - 3 seconds - show types added]**

"Perfect! The security types are now assigned to this model."

**[PAUSE - 2 seconds]**

**[1:30-1:50] Edit Security Model**

"To edit a security model, click the edit icon. I can update the model name, description, or other details. I'll update the description to be more specific about regional filtering rules."

**[PAUSE - 2 seconds]**

**[1:50-2:10] Remove Security Types**

"If I need to remove a security type from a model, I'll go to 'Manage Security Types', select the type I want to remove, and click 'Remove'. I can also use 'Remove All' to clear all types and start fresh, or 'Set All' to replace all existing types with a new set."

**[PAUSE - 2 seconds]**

**[2:10-2:25] View Security Model Details**

"Click on a security model to see full details including which security types are assigned, which reports use this model, and the model status."

**[PAUSE - 2 seconds]**

**[2:25-2:40] Activate/Deactivate Security Model**

"Use the status toggle to activate or deactivate a security model. Deactivated models won't be available for mapping to reports."

**[PAUSE - 2 seconds]**

**[2:40-3:00] Wrap-up**

"That covers security model management. You can create models, assign security types to them, edit details, remove types, and activate or deactivate models. Remember: security models are mapped to reports to control Row-Level Security, and security types define the dimension of that security - like Department or Region. That completes our overview of all Sakura features! Thanks for watching!"

---

## 📝 Production Notes

### Pauses Guide:
- **[PAUSE - 2 seconds]** = Brief pause for user to process
- **[PAUSE - 3 seconds]** = Longer pause for action completion or success message
- Natural pauses should occur between major steps

### Screen Actions to Show:
1. **Mouse movements** - Show cursor moving naturally
2. **Click animations** - Pause briefly after clicks
3. **Form filling** - Type naturally, don't rush
4. **Success messages** - Let them display fully before continuing
5. **Error scenarios** - Can be mentioned but don't need to show (keep videos positive)

### Real-World Examples Used:
- **Workspaces:** Marketing Workspace, Finance Workspace
- **Apps:** Sales Analytics Dashboard, Finance Dashboard
- **Audiences:** Finance Team, Executive Leadership, Sales Team
- **Reports:** Executive P&L Statement, Cash Flow Dashboard, P&L Statement
- **Security Models:** Regional Security Model, Department-Level Security
- **Security Types:** Region, Country, Department, Cost Center
- **Users:** Jane Smith, John Doe, Sarah Johnson, Mary Williams
- **Emails:** sales.manager@dentsu.com, finance.manager@dentsu.com, cfo@dentsu.com

### Timing Guidelines:
- Each video should be 2-3 minutes
- Allow natural pacing - don't rush
- If a video runs slightly over 3 minutes, that's acceptable
- Better to be clear and complete than rushed

### Recording Tips:
1. Use a clear, friendly voice
2. Speak slightly slower than normal conversation
3. Emphasize key terms (SAR, AUR, OLS Mode, etc.)
4. Show the mouse cursor clearly
5. Highlight important UI elements with brief pauses
6. Let success/error messages fully display
7. Use real data that makes sense contextually

---

**End of Scripts**
