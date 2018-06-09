﻿#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xDhcpServer' `
    -DSCResourceName 'MSFT_xDhcpReservedIPOptionValue' `
    -TestType Unit

#endregion HEADER


function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xDhcpReservedIPOptionValue' {
       
        $optionId      = 67
        $reservedIP    = '1.1.1.1'
        $value         = @('test Value')
        $vendorClass   = ''
        $userClass     = ''
        $addressFamily = 'IPv4'
        $ensure        = 'Present'

        $testParams = @{
            OptionId      = $optionId
            ReservedIP    = $reservedIP
            VendorClass   = $vendorClass
            UserClass     = $userClass
            AddressFamily = $addressFamily
        }

        $getFakeDhcpReservedIPv4OptionValue = {
            return @{
                OptionId      = $optionId
                Value         = $value
                VendorClass   = $vendorClass
                UserClass     = $userClass
                AddressFamily = $addressFamily
            }
        }

        $getFakeDhcpReservedIPv4OptionValueID168 = {
            return @{
                OptionId      = 168
                Value         = $value
                VendorClass   = $vendorClass
                UserClass     = $userClass
                AddressFamily = $addressFamily
            }
        }

        $getFakeDhcpReservedIPv4OptionValueDifferentValue = {
            return @{
                OptionId      = $optionId
                Value         = @('DifferentValue')
                VendorClass   = $vendorClass
                UserClass     = $userClass
                AddressFamily = $addressFamily
            }
        }

        Describe 'xDhcpServer\Get-TargetResource' {

            Mock Assert-Module -ModuleName OptionValueHelper  -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper -MockWith $GetFakeDhcpReservedIPv4OptionValue
       
            It 'Should call "Assert-Module" to ensure "DHCPServer" module is available' {
                 
                $result = Get-TargetResource @testParams -Ensure 'Present'

                Assert-MockCalled -CommandName Assert-Module -Scope It -ModuleName OptionValueHelper
            }

            It 'Returns a "System.Collections.Hashtable" object type' {

                $result = Get-TargetResource @testParams -Ensure 'Present'
                $result -is [System.Collections.Hashtable] | Should Be $true;
            }
        }
        
        Describe 'xDhcpServer\Test-TargetResource' {

            Mock Assert-Module -ModuleName OptionValueHelper -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }

            It 'Returns a "System.Boolean" object type' {
            
                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper -MockWith $GetFakeDhcpReservedIPv4OptionValue

                $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value
                $result  | Should BeOfType [System.Boolean]
            }
            
            It 'Returns $true when the option exists and Ensure = Present' {
                
                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper -MockWith $GetFakeDhcpReservedIPv4OptionValue
                
                $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value
                $result | Should Be $true
            }

            It 'Returns $false when the option does not exist and Ensure = Present' {
            
                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper {return $null}
                
                $result = Test-TargetResource @testParams -Ensure 'Present' -Value $value
                $result | Should Be $false
            }

            It 'Returns $false when the option exists and Ensure = Absent ' {

                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper -MockWith $GetFakeDhcpReservedIPv4OptionValue

                $result = Test-TargetResource @testParams -Ensure 'Absent' -Value $value
                $result | Should Be $false
            }
        }

        Describe 'xDhcpServer\Set-TargetResource' {
        
            Mock -CommandName Assert-Module -ModuleName OptionValueHelper -ParameterFilter { $ModuleName -eq 'DHCPServer' }
  
            Mock Remove-DhcpServerv4OptionValue -ModuleName OptionValueHelper 
            Mock Set-DhcpServerv4OptionValue -ModuleName OptionValueHelper 

            It 'Should call "Set-DhcpServerv4Optionvalue" when "Ensure" = "Present" and definition does not exist' {
                
                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper {return $null}

                Set-TargetResource @testParams -Ensure 'Present' -Value $value
                Assert-MockCalled -CommandName Set-DhcpServerv4OptionValue -Scope It -ModuleName OptionValueHelper
            }

            It 'Should call "Remove-DhcpServerv4OptionValue" when "Ensure" = "Absent" and Definition does exist' {
            
                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper -MockWith $GetFakeDhcpReservedIPv4OptionValue
                
                Set-TargetResource @testParams -Ensure 'Absent' -Value $value
                Assert-MockCalled -CommandName Remove-DhcpServerv4OptionValue -ModuleName OptionValueHelper -Scope It
            }

            It 'Should call "Set-DhcpServerv4OptionValue" when "Ensure" = "Present" and option value is different' {
            
                Mock Get-DhcpServerv4OptionValue -ModuleName OptionValueHelper -MockWith $getFakeDhcpReservedIPv4OptionValueDifferentValue

                Set-TargetResource @testParams -Ensure 'Present' -Value $value
                Assert-MockCalled -CommandName Set-DhcpServerv4OptionValue -ModuleName OptionValueHelper -Scope It
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
