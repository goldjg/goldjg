Imports System.Collections.ObjectModel
Imports System.Management.Automation
Imports System.Management.Automation.Runspaces
Imports System.Management.Automation.Host.PSHost
Imports System.Management.Automation.Host.PSHostRawUserInterface
Imports System.Management.Automation.Host.PSHostUserInterface
Imports System.Text
Imports System.IO

Module Module1
    Public Class PowerShellWorkBenchHost

        Inherits System.Management.Automation.Host.PSHost

        Public Overloads Overrides ReadOnly Property Name() As String

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides ReadOnly Property Version() As Version

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides ReadOnly Property InstanceId() As Guid

            Get

                Throw New NotImplementedException()

            End Get

        End Property


        Public Overloads Overrides ReadOnly Property UI() As System.Management.Automation.Host.PSHostUserInterface

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides ReadOnly Property CurrentCulture() As System.Globalization.CultureInfo

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides ReadOnly Property CurrentUICulture() As System.Globalization.CultureInfo

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides Sub SetShouldExit(exitCode As Integer)

            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Sub EnterNestedPrompt()

            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Sub ExitNestedPrompt()

            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Sub NotifyBeginApplication()

            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Sub NotifyEndApplication()

            Throw New NotImplementedException()

        End Sub



    End Class

    Public Class PowerShellWorkBenchHostRawUI
        Inherits System.Management.Automation.Host.PSHostRawUserInterface
        Public Overloads Overrides Property ForegroundColor() As ConsoleColor

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As ConsoleColor)
                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Property BackgroundColor() As ConsoleColor

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As ConsoleColor)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Property CursorPosition() As System.Management.Automation.Host.Coordinates

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As System.Management.Automation.Host.Coordinates)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Property WindowPosition() As System.Management.Automation.Host.Coordinates

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As System.Management.Automation.Host.Coordinates)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Property CursorSize() As Integer

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As Integer)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Property BufferSize() As System.Management.Automation.Host.Size

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As System.Management.Automation.Host.Size)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Property WindowSize() As System.Management.Automation.Host.Size

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As System.Management.Automation.Host.Size)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides ReadOnly Property MaxWindowSize() As System.Management.Automation.Host.Size

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides ReadOnly Property MaxPhysicalWindowSize() As System.Management.Automation.Host.Size

            Get

                Throw New NotImplementedException()

            End Get

        End Property

        Public Overloads Overrides ReadOnly Property KeyAvailable() As Boolean

            Get

                Throw New NotImplementedException()

            End Get

        End Property



        Public Overloads Overrides Property WindowTitle() As String

            Get

                Throw New NotImplementedException()

            End Get

            Set(value As String)

                Throw New NotImplementedException()

            End Set

        End Property



        Public Overloads Overrides Function ReadKey(options As System.Management.Automation.Host.ReadKeyOptions) As System.Management.Automation.Host.KeyInfo

            Throw New NotImplementedException()

        End Function



        Public Overloads Overrides Sub FlushInputBuffer()

            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Sub SetBufferContents(origin As System.Management.Automation.Host.Coordinates, contents As System.Management.Automation.Host.BufferCell(,))
            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Sub SetBufferContents(rectangle As System.Management.Automation.Host.Rectangle, fill As System.Management.Automation.Host.BufferCell)
            Throw New NotImplementedException()

        End Sub



        Public Overloads Overrides Function GetBufferContents(rectangle As System.Management.Automation.Host.Rectangle) As System.Management.Automation.Host.BufferCell(,)
            Throw New NotImplementedException()

        End Function



        Public Overloads Overrides Sub ScrollBufferContents(source As System.Management.Automation.Host.Rectangle, destination As System.Management.Automation.Host.Coordinates, clip As System.Management.Automation.Host.Rectangle, fill As System.Management.Automation.Host.BufferCell)

            Throw New NotImplementedException()

        End Sub



    End Class

    Public Class PoSHWrapper

        Public Shared Function RunScript(ByVal scriptText As String) As String

            Dim host As New PowerShellWorkBenchHost

            ' create Powershell runspace 
            Dim MyRunSpace As Runspace = RunspaceFactory.CreateRunspace(host)

            ' open it 
            MyRunSpace.Open()

            ' create a pipeline and feed it the script text 
            Dim MyPipeline As Pipeline = MyRunSpace.CreatePipeline()

            MyPipeline.Commands.AddScript(scriptText)

            ' add an extra command to transform the script output objects into nicely formatted strings 
            ' remove this line to get the actual objects that the script returns. For example, the script 
            ' "Get-Process" returns a collection of System.Diagnostics.Process instances. 
            'MyPipeline.Commands.Add("Out-String")

            ' execute the script 
            Dim results As Collection(Of PSObject) = MyPipeline.Invoke()

            ' close the runspace 
            MyRunSpace.Close()

            ' convert the script result into a single string 
            Dim MyStringBuilder As New StringBuilder()

            For Each obj As PSObject In results
                MyStringBuilder.AppendLine(obj.ToString())
            Next

            ' return the results of the script that has 
            ' now been converted to text 
            Return MyStringBuilder.ToString()

        End Function

        Public Shared Function LoadScript(ByVal filename As String) As String

            Try

                ' Create an instance of StreamReader to read from our file. 
                ' The using statement also closes the StreamReader. 
                Dim sr As New StreamReader(filename)

                ' use a string builder to get all our lines from the file 
                Dim fileContents As New StringBuilder()

                ' string to hold the current line 
                Dim curLine As String = ""

                ' loop through our file and read each line into our 
                ' stringbuilder as we go along 
                Do
                    ' read each line and MAKE SURE YOU ADD BACK THE 
                    ' LINEFEED THAT IT THE ReadLine() METHOD STRIPS OFF 
                    curLine = sr.ReadLine()
                    fileContents.Append(curLine + vbCrLf)
                Loop Until curLine Is Nothing

                ' close our reader now that we are done 
                sr.Close()

                ' call RunScript and pass in our file contents 
                ' converted to a string 
                Return fileContents.ToString()

            Catch e As Exception
                ' Let the user know what went wrong. 
                Dim errorText As String = "The file could not be read:"
                errorText += e.Message + "\n"
                Return errorText
            End Try

        End Function

        Public Shared Sub Main()
            RunScript(System.IO.File.ReadAllText("C:\HelloWorld.ps1"))
        End Sub

    End Class
End Module
