$InputLocation = "C:\convert"

$tool = 'C:Program Files (x86)\PDF Creator\PDFCreator.exe'
$tiffs = get-childitem  -filter *.tif -path $InputLocation

foreach($tiff in $tiffs)
{
    $filename = $tiff.FullName
    $pdf = $tiff.FullName.split('.')[0] + '.pdf'


    'Processing ' + $filename  + ' to ' + $pdf      
    $param = "-sOutputFile=$pdf"
    Start-Process $tool -ArgumentList ('/IF"' + $filename + '" /OF"' + $pdf + '/NoPSCheck /NoStart')

}