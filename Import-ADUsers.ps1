<#
    .SYNOPSIS
    Import-ADUsers.ps1

    .DESCRIPTION
    Import Active Directory users from CSV file.

    .LINK
    alitajran.com/import-ad-users-from-csv-powershell

    .NOTES
    Written by: ALI TAJRAN
    Website:    alitajran.com
    LinkedIn:   linkedin.com/in/alitajran

    .CHANGELOG
    V3.00, 08/11/2024 - Modified by https://github.com/BeanBagKing Original is here https://www.alitajran.com/import-ad-users-from-csv-powershell/
                      - This is a heavily modified version to grab fields from FakeNameGenerator builk output
                      - I've also added several things, such as a test variable that will not add users until it is flipped to false
                      - Randomized grabbing X number of users
                      - Tried to make the fields look like what you would find in a business.
    V2.00, 02/11/2024 - Refactored script
#>

# Define the CSV file location and import the data
$Csvfile = "C:\Users\Administrator\Documents\FakeNameGenerator.com.csv"
$Users = Import-Csv $Csvfile

$Test = $true
$UserLimit = 153 # The number of users that will be added to AD, change to taste

# Shuffle the users if you want to get random users
$ShuffledUsers = $Users | Get-Random -Count ($Users.Count)
# Limit to the first $UserLimit users
$Users = $ShuffledUsers | Select-Object -First $UserLimit

# Static variables for our data
$Company = Xxxxx Yyyyyy"
$Domain = "xxxxxyyyyyy"
$TLD = "zz" # Custom TLD - https://worldbuilding.stackexchange.com/a/68833

# Import the Active Directory module if not in test mode
if (-not $Test) {
    Import-Module ActiveDirectory
}

# Loop through each user
foreach ($User in $Users) {
    # Retrieve the Manager distinguished name if the Manager field is present
    $managerDN = $null
    if (-not $Test -and $User.Manager) {
        $managerDN = Get-ADUser -Filter "DisplayName -eq '$($User.Manager)'" -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
    }

    # Define the parameters using a hashtable
    $NewUserParams = @{
        Name                  = "$($User.GivenName) $($User.Surname)"
        GivenName             = $User.GivenName
        Surname               = $User.Surname
        DisplayName           = "$($User.GivenName) $($User.Surname)"
        SamAccountName        = "$($User.GivenName).$($User.Surname)".ToLower()
        UserPrincipalName     = "$($User.GivenName).$($User.Surname)".ToLower()+"@$($Domain).$($TLD)".ToLower()
        StreetAddress         = $User.StreetAddress
        City                  = $User.City
        State                 = $User.State
        PostalCode            = $User.ZipCode
        Country               = $User.Country
        Title                 = $User.Occupation
        Company               = $Company
        Manager               = $managerDN
        Path                  = "OU=Staff,DC=$Domain,DC=$TLD"
        Description           = $User.TropicalZodiac
        OfficePhone           = $User.TelephoneNumber
        EmailAddress          = "$($User.GivenName).$($User.Surname)".ToLower()+"@$($Domain).$($TLD)".ToLower()
        AccountPassword       = (ConvertTo-SecureString -AsPlainText "$($User.Password)" -Force)
        Enabled               = $true # Assuming accounts are enabled
        ChangePasswordAtLogon = $false # Set the "User must change password at next logon"
    }

    if (-not $Test) {
        # Add the info attribute to OtherAttributes only if Notes field contains a value
        if (![string]::IsNullOrEmpty($User.Notes)) {
            $NewUserParams.OtherAttributes = @{ info = $User.Notes }
        }

        # Check to see if the user already exists in AD
        if (Get-ADUser -Filter "SamAccountName -eq '$($NewUserParams.SamAccountName)'") {
            Write-Host "A user with username '$($NewUserParams.SamAccountName)' already exists in Active Directory." -ForegroundColor Yellow
        }
        else {
            # User does not exist, proceed to create the new user account
            New-ADUser @NewUserParams
            Write-Host "The user '$($NewUserParams.SamAccountName)' was created successfully." -ForegroundColor Green
        }
    }
    else {
        Write-Host @NewUserParams -ForegroundColor Green
        Write-Host "--------------------" -ForegroundColor Red
    }
}

