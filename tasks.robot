*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Desktop
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs
Library             RPA.Notifier


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret}=    Get Secret    credentials
    ${user_url}=    ${secret}[url]
    Log    ${secret}[url]
    #Open the robot order website
    &{orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Click Button    id:preview
        ${screenshot}=    Take screenshot of robot    ${row}[Order number]
        Click Button    id:order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot    ${screenshot}    ${pdf}
        Order another bot
    END
    Save as ZIP


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_as_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_for_order_${row}.PDF
    Html To Pdf    ${receipt_as_html}    ${pdf}

Take screenshot of robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    ${screenshot}=    Set Variable    ${OUTPUT_DIR}${/}images${/}/screenshot_${row}.png
    Screenshot    locator=css=#robot-preview-image    filename=${screenshot}

Embed the robot screenshot
    [Arguments]    ${pdf}    ${screenshot}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    image_path=${screenshot}    output_path=${pdf}
    Close Pdf    ${pdf}

Order another bot
    Wait Until Element Is Visible    id:order-another
    Click Button    Submit

Save as ZIP
    ${bot_orders}=    Set Variable    ${OUTPUT_DIR}/PDFs.ZIP
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}
    ...    ${bot_orders}

Paste csv
    Add heading    Send feedback
    Add text    Paste csv here:
    Add text input    link    label=URL Link
    ${result}=    Run dialog
    RETURN    ${result.link}
