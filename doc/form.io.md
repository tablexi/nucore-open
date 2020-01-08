# Form.io Tips & Tricks

## Form Setup & Integration

When setting up a form for the first time, the "Anonymous" user must be provided with access rights for NUcore integration to function properly

  1. Create the new form
  2. Click on the "Access" tab
  3. Reload the browser page to view the "Submission Data Permissions" section
  4. In "Submission Data Permissions", add the "Anonymous" role to:
    1. Create Own Submissions
    2. Create All Submissions
    3. Read Own Submissions
    4. Read All Submissions
    5. Update Own Submissions
    6. Update All Submissions
    7. Leave the "Form Definition Access" section alone
       * "Read Form Definition" will show "Administrator", "Authenticated", and "Anonymous"

The link to be entered and activated as an "Order Form" in NUcore
is located in the "Embed" tab; use the link listed just below the
"Form Embedded" text

## NUcore API Links

NUcore can port the following information to a form instance

  * User Name
  * User Email
  * User ID
  * Owner Name
  * Owner Email
  * Owner ID
  * Payment Source
  * Department Name
  * Order Date
  * NUcore Order Number

To accomplish this, the key located in the "API" tab for each
respective form component (listed parenthetically) must be keyed as
follows:

  * User Name -- orderedForName (Basic Components: Text Field)
  * User Email -- orderedForEmail (Basic Components: Text Field)
  * User ID -- orderedForUsernname (Basic Components: Text Field)
  * Owner Name -- accountOwnerName (Basic Components: Text Field)
  * Owner Email -- accountOwnerEmail (Basic Components: Text Field)
  * Owner ID -- accountOwnerUsername (Basic Components: Text Field)
  * Payment Source -- paymentSourceAccountNumber (Basic Components: Text Field)
  * Department Name -- departmentName (Basic Components: Text Field)
  * Order Date -- orderedAtDate (Advanced: Date/Time)
  * NUcore Order Number -- nucoreOrderNumber (Basic Components: Text Field)

## Advanced Topics

### File Upload

* When testing, forms setup in the form.io Staging environment
  must be pointed at the NUcore Staging Server; likewise, forms
  setup in the form.io Live environment must be pointed at the
  NUcore Production Server (different directories are setup in S3
  for the different environments)

* When setting up the "File Component", select S3 as the "Storage" option

* Set a reasonable "File Maximum Size" value (e.g. 10MB)

* Selecting the "Multiple Values" box enables users to upload
  multiple files to the form at once

### Actions tab -- setup multiple "Actions" upon form submission

* Possible to generate emails upon submission by adding an "Email Action"
* Possible to port data from one form to a separate "Resource" form
  1. Setup a separate "Resource" form in the "Resources" left-hand tab
  2. Create destination fields for the ported data
     * Component in the destination should match the components in the source form
     * If porting data from an "Edit/Data Grid", the API keys of parent and child components must match in both the source and the destination**

  3. Once the destination "Resource" is setup, a new "Action" must be setup in the source form, this "Action" must be the first/top "Action" in the source form for data to remain accessible upon form retrieval in NUcore

  4. In the existing Save Submission Action, change Save Submission from "This Form" to the new receiver form that you have setup
  5. Map the "Resource Fields" as appropriate and be sure to "Save Action"
  6. Create a second Save Submission Action, keeping the defaults for this second "Action" (Save Submission to "This Form") and be sure to "Save Action"

### Calculated Value Syntax

* Possible to populate a tertiary component with the output from combining other component values**

* For the calculated component, in the "Data" tab, under the "Calculated Value" section, enter custom code to accomplish this

  * Example syntax to add two cells: `value = (data.component_1_api_key || 0) + (data.component_2_api_key || 0);`

  * This syntax manages cases of "Component 1" or "Component 2" = 0

### Form View Pro -- Provide Core Managers Access to Forms without Access to form.io Project Management

1. In the given form.io Stage Environment, go to the “User” Resource
2. Click on the “Use” tab
3. Enter the desired Email and Password for the core manager and then “Submit” to add this as a “log in” data point
4. Decide which form will be accessed by a given core manager
  * If the form is a separate “Resource” populated by data ported over from a primary source form, then the customer-submitted data can be preserved independent of any edits or deletions to the new form
  * In “Submission Data Permissions”, add the “Authenticated” role to:
     * Create Own Submissions
     * Create All Submissions
     * Read Own Submissions
     * Read All Submissions
     * Update Own Submissions
     * Update All Submissions
5. Click the “Try Our Next Portal” button (upper-right corner)
6. Click the left-hand “Forms” tab
7. Click on the form whose access has been modified
8. Click on the “Launch” tab
9. Copy the URL available on this tab
10. The core manager can log in using this URL to access this form only, they can review all submissions, edit submission, delete submissions; they will not have access to the primary form.io stages

### PDF Generation Workflow

For all PDF-Generating Forms, the correct “PDF Token” is required; it is located:

1. Log in to form.io
2. Select “Project”
3. Go to the appropriate “Stage”
4. Go to “Settings” (left-hand navigation panel)
5. Go to “PDF Management” (new left-hand navigation panel)
6. Go to the “Enterprise” tab (top navigation selector)
7. See the “PDF Token” field

For all related Forms, “Access” must be set to “Anonymous” as noted in “Form Setup and Integration” section 1(d)

#### Generate PDF of Current Form View

Replaces the “Submit” button with a button that submits the form and generates a PDF download of the current form view (including the data)

In the Submit “Button Component” make these changes

* Change the “Label” to indicate the button’s dual functions
* Change the “Action” to “Custom”
* Add “Button Custom Logic” from the text file “Form.io Examples” under the section “Generate PDF of Current Form View”
* Must set “var fileToken” with the appropriate PDF Token
* Must set “var currentForm” with the “embed” link of the current form
* The “var pdfFileName” sets the default file name for the downloaded PDF (can be altered if desired)
  * Currently set to concatenate fields from our API ported fields (User ID and NUcore Order ID)
* Update the three “instance.label” values, if desired
* Default is “Generating Preview”, “Downloading PDF”, and “Saving”

#### Generate In-Line Custom PDF within Current Form

Allows a user to preview and download a custom PDF with data from the current “Parent Form”

1. Create a new, separate “PDF Form” (set the “Access” permissions)
  1. Upload a blank PDF to be used as the template for the PDF
  2. Add “Text Fields” to the “PDF Form” as needed, positioning appropriately
     * The API value of each “Text Field” will need to match the API value of the data that will be ported from the “Parent Form” (Parent Form is the form where the PDF will be nested)
  3. In the “Parent Form” where the In-Line PDF will be generated, setup the following
     1. Create a selector to toggle the PDF View
         * Use a “Check Box” Component
         * Note the API of this new toggle component
     2. From the “Premium” Component Section, add a “Nested Form”
         1. Name the Component
         2. Set the “Form” selection to the PDF Form to be displayed
         3. In the “Data” tab, set the “Calculated Value” to reference the data as follows

            ```
            data.[nested_component_api].data.[component_in_pdf_api] = data.[component_in_parent_api] ? data.[component_in_parent_api] : ''; 
            [repeat_the_syntax_for_more_fields]; 
            instance.redraw();
            ```
           
            * `[nested_component_api]` is from the API tab of the “Nested Form Component”
            * `[component_in_pdf_api]` is from the API tab of the particular field in the PDF Form itself
            * `[component_in_parent_api]` is the data from the Parent Form that should be displayed in this field
        
        4. In the “Conditional” tab, set “Advanced” as follows
show = data.[api key of the toggle component];
[api key of the toggle component] is from the API tab of the toggle component (check box)
From the “Data” Component Section, add a “Hidden” Component
Name the Component
In the “Data” tab, set the “Custom Default Value” to reference the data as follows
data.[nested_component_api] = {data: {}};
Definitions same as above
In the “Data” tab, set the “Calculated Value” to reference the data as follows
data.[nested_component_api].data.[component_in_pdf_api] = data.[component_in_parent_api]? data.[component_in_parent_api] : ''; [repeat_the_syntax_for_more_fields];
Definitions same as above
Add a “Button” Component to download the PDF
Change the “Label” to indicate the Download function
Change the “Action” to “Custom”
Add “Button Custom Logic” from the text file “Form.io Examples” under the section “Generate PDF of Current Form View”
Must set “var fileToken” with the appropriate PDF Token
Must set “var pdf” with the “embed” link of the PDF Form that is located in the “Nested Form”
The “var pdfFileName” sets the default file name for the downloaded PDF (can be altered if desired)
Currently set to concatenate fields from our API ported fields (User ID and NUcore Order ID)
Update the “instance.label” value, if desired
Default is “Print Tag”