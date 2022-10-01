*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Variables ***
#${SITE_URL}    Get Secrets
${DOWNLOAD_ORDER_FILEPATH}      ${CURDIR}${/}data${/}orders.csv
${ZIP_FILEPATH}                 ${OUTPUT_DIR}${/}receipts.Zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Log    Hello World.
    ${orders_report_url}=    Input form dialog
    Open the website
    ${orders}=    Get orders    ${orders_report_url}[\URL]
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Close the modal window
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser


*** Keywords ***
Open the website
    ${site_url}=    Get url from vault
    Open Available Browser    ${site_url}

Close the modal window
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Get orders
    [Arguments]    ${orders_report_url}
    Download    ${orders_report_url}    target_file=${DOWNLOAD_ORDER_FILEPATH}    overwrite=True
    ${orderTable}=    Read table from CSV    ${DOWNLOAD_ORDER_FILEPATH}    header=True
    RETURN    ${orderTable}

Fill the form
    [Arguments]    ${order}
    Select From List By Index    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://*[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${Order number}.pdf
    Html To Pdf    ${receipt}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${Order number}
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}screenshots${/}${Order number}.png
    Screenshot    id:robot-preview-image    ${screenshot_path}
    RETURN    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files list}=    Create List    ${screenshot}
    Add Files To Pdf    ${files list}    ${pdf}    append=True

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${ZIP_FILEPATH}

Input form dialog
    Add heading    Please enter the URL of the CSV file.
    Add text input    URL    label= CSV file URL
    ${result}=    Run dialog
    RETURN    ${result}

Close the browser
    Close Browser

Get url from vault
    ${secret}=    Get Secret    credentials
    Log    ${secret}[site_url]
    RETURN    ${secret}[site_url]
