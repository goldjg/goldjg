$test = 'Global Scope'  
Function Foo {  
    $test = 'Function Scope'  
    Write-Host $Global:test                                  # Global Scope  
    Write-Host $Local:test                                   # Function Scope  
    Write-Host (Get-Variable -Name test -ValueOnly -Scope 0) # Function Scope  
    Write-Host (Get-Variable -Name test -ValueOnly -Scope 1) # Global Scope   
}  
Foo