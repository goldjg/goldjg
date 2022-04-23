//Simple PowerShell host created by Ingo Karstein (http://ikarstein.wordpress.com)
//   for PS2EXE (http://ps2exe.codeplex.com)


using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using PowerShell = System.Management.Automation.PowerShell;
using System.Globalization;
using System.Management.Automation.Host;
using System.Security;
using System.Reflection;
using System.IO;
using System.Security.Cryptography;

    public class AesExample
    {

        public static byte[] EncryptStringToBytes_Aes(string plainText, byte[] Key,byte[] IV)
        {
            // Check arguments. 
            if (plainText == null || plainText.Length <= 0)
                throw new ArgumentNullException("plainText");
            if (Key == null || Key.Length <= 0)
                throw new ArgumentNullException("Key");
            if (IV == null || IV.Length <= 0)
                throw new ArgumentNullException("Key");
            byte[] encrypted;
            // Create an Aes object 
            // with the specified key and IV. 
            using (Aes aesAlg = Aes.Create())
            {
                aesAlg.Key = Key;
                aesAlg.IV = IV;

                // Create a decryptor to perform the stream transform.
                ICryptoTransform encryptor = aesAlg.CreateEncryptor(aesAlg.Key, aesAlg.IV);

                // Create the streams used for encryption. 
                using (MemoryStream msEncrypt = new MemoryStream())
                {
                    using (CryptoStream csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                    {
                        using (StreamWriter swEncrypt = new StreamWriter(csEncrypt))
                        {

                            //Write all data to the stream.
                            swEncrypt.Write(plainText);
                        }
                        encrypted = msEncrypt.ToArray();
                    }
                }
            }


            // Return the encrypted bytes from the memory stream. 
            return encrypted;

        }

        public static string DecryptStringFromBytes_Aes(byte[] cipherText, byte[] Key, byte[] IV)
        {
            // Check arguments. 
            if (cipherText == null || cipherText.Length <= 0)
                throw new ArgumentNullException("cipherText");
            if (Key == null || Key.Length <= 0)
                throw new ArgumentNullException("Key");
            if (IV == null || IV.Length <= 0)
                throw new ArgumentNullException("Key");

            // Declare the string used to hold 
            // the decrypted text. 
            string plaintext = null;

            // Create an Aes object 
            // with the specified key and IV. 
            using (Aes aesAlg = Aes.Create())
            {
                aesAlg.Key = Key;
                aesAlg.IV = IV;

                // Create a decryptor to perform the stream transform.
                ICryptoTransform decryptor = aesAlg.CreateDecryptor(aesAlg.Key, aesAlg.IV);

                // Create the streams used for decryption. 
                using (MemoryStream msDecrypt = new MemoryStream(cipherText))
                {
                    using (CryptoStream csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read))
                    {
                        using (StreamReader srDecrypt = new StreamReader(csDecrypt))
                        {

                            // Read the decrypted bytes from the decrypting stream
                                // and place them in a string.
                                                        plaintext = srDecrypt.ReadToEnd();
                        }
                    }
                }

            }

            return plaintext;

        }
    }



namespace ik.PowerShell
{
    internal class PS2EXEHostRawUI : PSHostRawUserInterface
    {
        public override ConsoleColor BackgroundColor
        {
            get
            {
                return Console.BackgroundColor;
            }
            set
            {
                Console.BackgroundColor = value;
            }
        }

        public override Size BufferSize
        {
            get
            {
                return new Size(Console.BufferWidth, Console.BufferHeight);
            }
            set
            {
                Console.BufferWidth = value.Width;
                Console.BufferHeight = value.Height;
            }
        }

        public override Coordinates CursorPosition
        {
            get
            {
                return new Coordinates(Console.CursorLeft, Console.CursorTop);
            }
            set
            {
                Console.CursorTop = value.Y;
                Console.CursorLeft = value.X;
            }
        }

        public override int CursorSize
        {
            get
            {
                return Console.CursorSize;
            }
            set
            {
                Console.CursorSize = value;
            }
        }

        public override void FlushInputBuffer()
        {
            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.FlushInputBuffer");
        }

        public override ConsoleColor ForegroundColor
        {
            get
            {
                return Console.ForegroundColor;
            }
            set
            {
                Console.ForegroundColor = value;
            }
        }

        public override BufferCell[,] GetBufferContents(Rectangle rectangle)
        {
            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.GetBufferContents");
        }

        public override bool KeyAvailable
        {
            get
            {
                throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.KeyAvailable/Get");
            }
        }

        public override Size MaxPhysicalWindowSize
        {
            get { return new Size(Console.LargestWindowWidth, Console.LargestWindowHeight); }
        }

        public override Size MaxWindowSize
        {
            get { return new Size(Console.BufferWidth, Console.BufferWidth); }
        }

        public override KeyInfo ReadKey(ReadKeyOptions options)
        {
            ConsoleKeyInfo cki = Console.ReadKey();

            ControlKeyStates cks = 0;
            if ((cki.Modifiers & ConsoleModifiers.Alt) != 0)
                cks |= ControlKeyStates.LeftAltPressed | ControlKeyStates.RightAltPressed;
            if ((cki.Modifiers & ConsoleModifiers.Control) != 0)
                cks |= ControlKeyStates.LeftCtrlPressed | ControlKeyStates.RightCtrlPressed;
            if ((cki.Modifiers & ConsoleModifiers.Shift) != 0)
                cks |= ControlKeyStates.ShiftPressed;
            if (Console.CapsLock)
                cks |= ControlKeyStates.CapsLockOn;

            return new KeyInfo((int)cki.Key, cki.KeyChar, cks, false);
        }

        public override void ScrollBufferContents(Rectangle source, Coordinates destination, Rectangle clip, BufferCell fill)
        {
            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.ScrollBufferContents");
        }

        public override void SetBufferContents(Rectangle rectangle, BufferCell fill)
        {
            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.SetBufferContents(1)");
        }

        public override void SetBufferContents(Coordinates origin, BufferCell[,] contents)
        {
            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.SetBufferContents(2)");
        }

        public override Coordinates WindowPosition
        {
            get
            {
                Coordinates s = new Coordinates();
                s.X = Console.WindowLeft;
                s.Y = Console.WindowTop;
                return s;
            }
            set
            {
                Console.WindowLeft = value.X;
                Console.WindowTop = value.Y;
            }
        }

        public override Size WindowSize
        {
            get
            {
                Size s = new Size();
                s.Height = Console.WindowHeight;
                s.Width = Console.WindowWidth;
                return s;
            }
            set
            {
                Console.WindowWidth = value.Width;
                Console.WindowHeight = value.Height;
            }
        }

        public override string WindowTitle
        {
            get
            {
                return Console.Title;
            }
            set
            {
                Console.Title = value;
            }
        }
    }
    internal class PS2EXEHostUI : PSHostUserInterface
    {
        private PS2EXEHostRawUI rawUI = null;

        public PS2EXEHostUI()
            : base()
        {
            rawUI = new PS2EXEHostRawUI();
        }

        public override Dictionary<string, PSObject> Prompt(string caption, string message, System.Collections.ObjectModel.Collection<FieldDescription> descriptions)
        {
            if (!string.IsNullOrEmpty(caption))
                WriteLine(caption);
            if (!string.IsNullOrEmpty(message))
                WriteLine(message);
            Dictionary<string, PSObject> ret = new Dictionary<string, PSObject>();
            foreach (FieldDescription cd in descriptions)
            {
                Type t = null;
                if (string.IsNullOrEmpty(cd.ParameterAssemblyFullName))
                    t = typeof(string);
                else t = Type.GetType(cd.ParameterAssemblyFullName);


                if (t.IsArray)
                {
                    Type elementType = t.GetElementType();
                    Type genericListType = Type.GetType("System.Collections.Generic.List" + ((char)0x60).ToString() + "1");
                    genericListType = genericListType.MakeGenericType(new Type[] { elementType });
                    ConstructorInfo constructor = genericListType.GetConstructor(BindingFlags.CreateInstance | BindingFlags.Instance | BindingFlags.Public, null, Type.EmptyTypes, null);
                    object resultList = constructor.Invoke(null);

                    int index = 0;
                    string data = "";
                    do
                    {
                        try
                        {
                            if (!string.IsNullOrEmpty(cd.Name))
                                Write(string.Format("{0}[{1}]: ", cd.Name, index));
                            data = ReadLine();

                            if (string.IsNullOrEmpty(data))
                                break;

                            object o = System.Convert.ChangeType(data, elementType);

                            genericListType.InvokeMember("Add", BindingFlags.InvokeMethod | BindingFlags.Public | BindingFlags.Instance, null, resultList, new object[] { o });
                        }
                        catch (Exception ex)
                        {
                            throw new Exception("Exception in ik.PowerShell.PS2EXEHostUI.Prompt*1");
                        }
                        index++;
                    } while (true);

                    System.Array retArray = (System.Array)genericListType.InvokeMember("ToArray", BindingFlags.InvokeMethod | BindingFlags.Public | BindingFlags.Instance, null, resultList, null);
                    ret.Add(cd.Name, new PSObject(retArray));
                }
                else
                {

                    if (!string.IsNullOrEmpty(cd.Name))
                        Write(string.Format("{0}: ", cd.Name));
                    object o = null;

                    string l = null;
                    try
                    {
                        l = ReadLine();

                        if (string.IsNullOrEmpty(l))
                            o = cd.DefaultValue;
                        if (o == null)
                        {
                            o = System.Convert.ChangeType(l, t);
                        }

                        ret.Add(cd.Name, new PSObject(o));
                    }
                    catch
                    {
                        throw new Exception("Exception in ik.PowerShell.PS2EXEHostUI.Prompt*2");
                    }
                }
            }
            return ret;
        }

        public override int PromptForChoice(string caption, string message, System.Collections.ObjectModel.Collection<ChoiceDescription> choices, int defaultChoice)
        {
            if (!string.IsNullOrEmpty(caption))
                WriteLine(caption);
            WriteLine(message);
            int idx = 0;
            SortedList<string, int> res = new SortedList<string, int>();
            foreach (ChoiceDescription cd in choices)
            {

                string l = cd.Label;
                int pos = cd.Label.IndexOf('&');
                if (pos > -1)
                {
                    l = cd.Label.Substring(pos + 1, 1);
                }
                res.Add(l.ToLower(), idx);

                if (idx == defaultChoice)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Write(ConsoleColor.Yellow, Console.BackgroundColor, string.Format("[{0}]: ", l, cd.HelpMessage));
                    WriteLine(ConsoleColor.Gray, Console.BackgroundColor, string.Format("{1}", l, cd.HelpMessage));
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.White;
                    Write(ConsoleColor.White, Console.BackgroundColor, string.Format("[{0}]: ", l, cd.HelpMessage));
                    WriteLine(ConsoleColor.Gray, Console.BackgroundColor, string.Format("{1}", l, cd.HelpMessage));
                }
                idx++;
            }

            try
            {
                string s = Console.ReadLine().ToLower();
                if (res.ContainsKey(s))
                {
                    return res[s];
                }
            }
            catch { }


            return -1;
        }

        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes allowedCredentialTypes, PSCredentialUIOptions options)
        {
            if (!string.IsNullOrEmpty(caption))
                WriteLine(caption);
            WriteLine(message);
            Write("User name: ");
            string un = ReadLine();
            SecureString pwd = null;
            if ((options & PSCredentialUIOptions.ReadOnlyUserName) == 0)
            {
                Write("Password: ");
                pwd = ReadLineAsSecureString();
            }
            PSCredential c = new PSCredential(un, pwd);
            return c;
        }

        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName)
        {
            if (!string.IsNullOrEmpty(caption))
                WriteLine(caption);
            WriteLine(message);
            Write("User name: ");
            string un = ReadLine();
            Write("Password: ");
            SecureString pwd = ReadLineAsSecureString();
            PSCredential c = new PSCredential(un, pwd);
            return c;
        }

        public override PSHostRawUserInterface RawUI
        {
            get
            {
                return rawUI;
            }
        }

        public override string ReadLine()
        {
            return Console.ReadLine();
        }

        public override System.Security.SecureString ReadLineAsSecureString()
        {
            System.Security.SecureString x = new System.Security.SecureString();
            string l = Console.ReadLine();
            foreach (char c in l.ToCharArray())
                x.AppendChar(c);
            return x;
        }

        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
        {
            Console.ForegroundColor = foregroundColor;
            Console.BackgroundColor = backgroundColor;
            Console.Write(value);
        }

        public override void Write(string value)
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.Write(value);
        }

        public override void WriteDebugLine(string message)
        {
            Console.ForegroundColor = ConsoleColor.DarkMagenta;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.WriteLine(message);
        }

        public override void WriteErrorLine(string value)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.WriteLine(value);
        }

        public override void WriteLine(string value)
        {
            Console.ForegroundColor = ConsoleColor.White;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.WriteLine(value);
        }

        public override void WriteProgress(long sourceId, ProgressRecord record)
        {

        }

        public override void WriteVerboseLine(string message)
        {
            Console.ForegroundColor = ConsoleColor.DarkCyan;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.WriteLine(message);
        }

        public override void WriteWarningLine(string message)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.WriteLine(message);
        }
    }



    internal class PS2EXEHost : PSHost
    {
        private PS2EXEApp parent;
        private PS2EXEHostUI ui = null;

        private CultureInfo originalCultureInfo =
            System.Threading.Thread.CurrentThread.CurrentCulture;

        private CultureInfo originalUICultureInfo =
            System.Threading.Thread.CurrentThread.CurrentUICulture;

        private Guid myId = Guid.NewGuid();

        public PS2EXEHost(PS2EXEApp app, PS2EXEHostUI ui)
        {
            this.parent = app;
            this.ui = ui;
        }

        public override System.Globalization.CultureInfo CurrentCulture
        {
            get
            {
                return this.originalCultureInfo;
            }
        }

        public override System.Globalization.CultureInfo CurrentUICulture
        {
            get
            {
                return this.originalUICultureInfo;
            }
        }

        public override Guid InstanceId
        {
            get
            {
                return this.myId;
            }
        }

        public override string Name
        {
            get
            {
                return "PS2EXE_Host";
            }
        }

        public override PSHostUserInterface UI
        {
            get
            {
                return ui;
            }
        }

        public override Version Version
        {
            get
            {
                return new Version(0, 2, 0, 0);
            }
        }

        public override void EnterNestedPrompt()
        {
        }

        public override void ExitNestedPrompt()
        {
        }

        public override void NotifyBeginApplication()
        {
            return;
        }

        public override void NotifyEndApplication()
        {
            return;
        }

        public override void SetShouldExit(int exitCode)
        {
            this.parent.ShouldExit = true;
            this.parent.ExitCode = exitCode;
        }
    }



    internal interface PS2EXEApp
    {
        bool ShouldExit { get; set; }
        int ExitCode { get; set; }
    }


    internal class PS2EXE : PS2EXEApp
    {

        private bool shouldExit;

        private int exitCode;

        public bool ShouldExit
        {
            get { return this.shouldExit; }
            set { this.shouldExit = value; }
        }

        public int ExitCode
        {
            get { return this.exitCode; }
            set { this.exitCode = value; }
        }

        private static int Main(string[] args)
        {
            PS2EXE me = new PS2EXE();

            bool paramWait = false;
            string extractFN = string.Empty;

            PS2EXEHostUI ui = new PS2EXEHostUI();
            PS2EXEHost host = new PS2EXEHost(me, ui);
            System.Threading.ManualResetEvent mre = new System.Threading.ManualResetEvent(false);

            AppDomain.CurrentDomain.UnhandledException += new UnhandledExceptionEventHandler(CurrentDomain_UnhandledException);

            // encryption test /////////////////////////////////////////////////////////////////////////

            try
            {

                string original = "Here is some data to encrypt!";
                byte[] Key = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 
                               0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
                               0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24,
                               0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32 };

                byte[] AltKey = { 0x11, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 
                               0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16,
                               0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24,
                               0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32 };

                // Create a new instance of the Aes 
                // class.  This generates a new key and initialization  
                // vector (IV). 
                using (Aes myAes = Aes.Create())
                {

                    myAes.Key = Key;
                    myAes.IV = System.Text.Encoding.Unicode.GetBytes("29031979");

                    // Encrypt the string to an array of bytes. 
                    byte[] encrypted = AesExample.EncryptStringToBytes_Aes(original, myAes.Key, myAes.IV);

                    myAes.Key = AltKey;

                    // Decrypt the bytes to a string. 
                    string roundtrip = AesExample.DecryptStringFromBytes_Aes(encrypted, myAes.Key, myAes.IV);

                    //Display the original data and the decrypted data.
                    Console.WriteLine("Original:   {0}", original);
                    Console.WriteLine("Round Trip: {0}", roundtrip);
                }

            }
            catch (Exception e)
            {
                Console.WriteLine("Error: {0}", e.Message);
            }

            //encryption test end ///////////////////////////////////////////////////////////////////


            try
            {
                using (Runspace myRunSpace = RunspaceFactory.CreateRunspace(host))
                {
                    myRunSpace.Open();

                    using (System.Management.Automation.PowerShell powershell = System.Management.Automation.PowerShell.Create())
                    {
                        Console.CancelKeyPress += new ConsoleCancelEventHandler(delegate(object sender, ConsoleCancelEventArgs e)
                        {
                            try
                            {
                                powershell.BeginStop(new AsyncCallback(delegate(IAsyncResult r)
                                {
                                    mre.Set();
                                    e.Cancel = true;
                                }), null);
                            }
                            catch
                            {
                            };
                        });

                        powershell.Runspace = myRunSpace;
                        powershell.Streams.Progress.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
                        {
                            ui.WriteLine(((PSDataCollection<ProgressRecord>)sender)[e.Index].ToString());
                        });
                        powershell.Streams.Verbose.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
                        {
                            ui.WriteVerboseLine(((PSDataCollection<VerboseRecord>)sender)[e.Index].ToString());
                        });
                        powershell.Streams.Warning.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
                        {
                            ui.WriteWarningLine(((PSDataCollection<WarningRecord>)sender)[e.Index].ToString());
                        });
                        powershell.Streams.Error.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
                        {
                            ui.WriteErrorLine(((PSDataCollection<ErrorRecord>)sender)[e.Index].ToString());
                        });

                        PSDataCollection<PSObject> inp = new PSDataCollection<PSObject>();
                        inp.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
                        {
                            ui.WriteLine(inp[e.Index].ToString());
                        });

                        PSDataCollection<PSObject> outp = new PSDataCollection<PSObject>();
                        outp.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
                        {
                            ui.WriteLine(outp[e.Index].ToString());
                        });

                        int separator = 0;
                        int idx = 0;
                        foreach (string s in args)
                        {
                            if (string.Compare(s, "-wait", true) == 0)
                                paramWait = true;
                            else if (s.StartsWith("-extract", StringComparison.InvariantCultureIgnoreCase))
                            {
                                string[] s1 = s.Split(new string[] { ":" }, 2, StringSplitOptions.RemoveEmptyEntries);
                                if (s1.Length != 2)
                                {
                                    Console.WriteLine("If you specify the -extract option you need to add a file for extraction in this way\r\n   -extract:\"<filename>\"");
                                    return 1;
                                }
                                extractFN = s1[1].Trim(new char[] { '\"' });
                            }
                            else if (string.Compare(s, "-end", true) == 0)
                            {
                                separator = idx + 1;
                                break;
                            }
                            else if (string.Compare(s, "-debug", true) == 0)
                            {
                                System.Diagnostics.Debugger.Break();
                                break;
                            }
                            idx++;
                        }

                        // Here is where we read stored script

                        string encscript = "I2dldCByZHAgZ3JvdXAgbGlzdA0KJHNlcnZlcnMgPSBnZXQtY29udGVudCBcXGxncmRjcHBkdDM5XG02MTg4OVxSRFBfR3JvdXAudHh0DQokbWVzcnYgPSAoR2V0LVdtaU9iamVjdCBXaW4zMl9Db21wdXRlclN5c3RlbSkuTmFtZTsNCiRtZWRvbSA9IChHZXQtV21pT2JqZWN0IFdpbjMyX0xvZ2dlZE9uVXNlciAtY29tcHV0ZXJuYW1lIGxvY2FsaG9zdHxgDQogICAgICAgICAgICBzZWxlY3QgQW50ZWNlZGVudCAtZmlyc3QgMSkuQW50ZWNlZGVudC5zcGxpdCgiLiIpWzJdLnNwbGl0KCIsIilbMF0uc3BsaXQoJyInKVsxXTsNCiRtZXVzciA9IChHZXQtV21pT2JqZWN0IFdpbjMyX0xvZ2dlZE9uVXNlciAtY29tcHV0ZXJuYW1lIGxvY2FsaG9zdHxgDQogICAgICAgICAgICBzZWxlY3QgQW50ZWNlZGVudCAtZmlyc3QgMSkuQW50ZWNlZGVudC5zcGxpdCgiLiIpWzJdLnNwbGl0KCIsIilbMV0uc3BsaXQoJyInKVsxXTsNCiRzaWQgPSAoW3dtaV0oIndpbjMyX1VzZXJBY2NvdW50LkRvbWFpbj0nIiArICRtZWRvbSArICInLE5hbWU9JyIgKyAkbWV1c3IgKyAiJyIpKS5zaWQNCltkb3VibGVdJHNhbHQgPSAoJHNpZC5SZXBsYWNlKCItIiwiIikuUmVwbGFjZSgiUyIsIiIpICogKCRtZXNydi5sZW5ndGgvMikpDQpjbGVhci1pdGVtIHZhcmlhYmxlOnNpZCAtZm9yY2UNCg0KI2ZvciBlYWNoIGxpbmUgaW4gdGhlIGxpc3QsIHByb2Nlc3MgaXQuLi4NCmZvcmVhY2ggKCRsaW5lIGluICRzZXJ2ZXJzKSB7DQogICAgI2NyZWF0ZSBrZXkNCiAgICANCiAgICBbc3RyaW5nXSRyc3RyaW5nPSgoJHNhbHQuVG9TdHJpbmcoKS5TcGxpdCgiRSIpWzBdKSArICRtZXNydik7DQogICAgJHJsZW5ndGggPSAkcnN0cmluZy5sZW5ndGg7DQogICAgJHJwYWQgPSAzMi0kcmxlbmd0aDsNCiAgICBpZiAoKCRybGVuZ3RoIC1sdCAxNikgLW9yICgkcmxlbmd0aCAtZ3QgMzIpKSB7VGhyb3cgIlN0cmluZyBtdXN0IGJlIGJldHdlZW4gMTYgYW5kIDMyIGNoYXJhY3RlcnMifTsNCiAgICAkcmVuY29kaW5nID0gTmV3LU9iamVjdCBTeXN0ZW0uVGV4dC5BU0NJSUVuY29kaW5nOw0KICAgICRya2V5ID0gJHJlbmNvZGluZy5HZXRCeXRlcygkcnN0cmluZyArICIwIiAqICRycGFkKTsNCg0KICAgICNmb3JjaWJseSByZW1vdmUgdmFyaWFibGVzIHVzZWQgaW4ga2V5IGdlbmVyYXRpb24gYW5kIHRoZWlyIGNvbnRlbnRzDQogICAgY2xlYXItaXRlbSB2YXJpYWJsZTpyc3RyaW5nIC1mb3JjZTsNCiAgICBjbGVhci1pdGVtIHZhcmlhYmxlOnJwYWQgLWZvcmNlOw0KICAgIGNsZWFyLWl0ZW0gdmFyaWFibGU6cmxlbmd0aCAtZm9yY2U7DQogICAgY2xlYXItaXRlbSB2YXJpYWJsZTpyZW5jb2RpbmcgLWZvcmNlOw0KICAgIA0KICAgICNzcGxpdCB0aGUgbGluZSBpbnRvIHNlcnZlciwgZG9tYWluLCB1c2VyIGFuZCBlbmNyeXB0ZWQgcGFzc3dvcmQNCiAgICAkcnNydj0kbGluZS5zcGxpdCgiLCIpWzBdOw0KICAgICRyZG9tPSRsaW5lLnNwbGl0KCIsIilbMV07DQogICAgJHJ1c3I9JGxpbmUuc3BsaXQoIiwiKVsyXTsNCiAgICAkcmVuY3Bzcz0kbGluZS5zcGxpdCgiLCIpWzNdOw0KICAgIGNsZWFyLWl0ZW0gdmFyaWFibGU6bGluZSAtZm9yY2U7ICNmb3JjaWJseSByZW1vdmUgdGhlIHZhcmlhYmxlIHN0b3JpbmcgbGluZSB5b3UgcmVhZCBpbiBub3cgdGhhdCBpdCdzIHByb2Nlc3NlZA0KICAgIA0KICAgICNkZWNyeXB0IHRoZSBwYXNzd29yZCAtIHdpbGwgZmFpbCBpZiBpbmNvcnJlY3Qga2V5IChuZWVkIHRvIGFkZCBlcnJvciBoYW5kbGluZywgY3VycmVudGx5IGJvbWJzIG91dCBlbnRpcmUgc2NyaXB0DQogICAgJHJwc3M9W1J1bnRpbWUuSW50ZXJvcFNlcnZpY2VzLk1hcnNoYWxdOjpQdHJUb1N0cmluZ0F1dG8oW1J1bnRpbWUuSW50ZXJvcFNlcnZpY2VzLk1hcnNoYWxdOjpTZWN1cmVTdHJpbmdUb0JTVFIoKGANCiAgICBDb252ZXJ0VG8tU2VjdXJlU3RyaW5nICRyZW5jcHNzIC1rZXkgJHJrZXkpKSk7DQogICAgDQogICAgI2ZvcmNpYmx5IHJlbW92ZSB0aGUga2V5IHZhcmlhYmxlIGFuZCBlbmNyeXB0ZWQgcGFzc3dvcmQgdmFyaWFibGUgYW5kIHRoZWlyIGNvbnRlbnRzDQogICAgY2xlYXItaXRlbSB2YXJpYWJsZTpya2V5IC1mb3JjZTsNCiAgICBjbGVhci1pdGVtIHZhcmlhYmxlOnJlbmNwc3MgLWZvcmNlOw0KICAgIA0KICAgICNnZW5lcmF0ZSBjcmVkZW50aWFsIGZvciB0aGlzIHNlcnZlci91c2VyIGluIHdpbmRvd3MgY3JlZGVudGlhbHMgc3RvcmUNCiAgICAkY21kID0gKCJjbWRrZXkgL2dlbmVyaWM6VEVSTVNSVi8iICsgJHJzcnYgKyAiIC91c2VyOiIgKyAkcmRvbSArICJcIiArICRydXNyICsgIiAvcGFzczoiICsgJHJwc3MpOw0KICAgIGNsZWFyLWl0ZW0gdmFyaWFibGU6cnBzcyAtZm9yY2U7DQoJaW52b2tlLWV4cHJlc3Npb24gLWNvbW1hbmQgJGNtZHxvdXQtbnVsbDsNCiAgICBjbGVhci1pdGVtIHZhcmlhYmxlOmNtZCAtZm9yY2U7DQogICAgDQogICAgI2xhdW5jaCBSRFAgc2Vzc2lvbiB0byBzZXJ2ZXINCiAgICBtc3RzYyAvdjokcnNydiAvdzoxMDI0IC9oOjc2ODsNCiAgICANCiAgICAjd2FpdCAyIHNlY29uZHMgdG8gYWxsb3cgbXN0c2MgdG8gbGF1bmNoLCB0aGVuIGRlbGV0ZSBjcmVkZW50aWFsIGZyb20gc3RvcmUgKG1heSBuZWVkIHRvIGJlZWYgdXAgdG8gaGFuZGxlIG5ldHdvcmsgaXNzdWVzDQogICAgc2xlZXAgMjsNCiAgICBpbnZva2UtZXhwcmVzc2lvbiAtY29tbWFuZCAoImNtZGtleSAvZGVsZXRlOlRFUk1TUlYvIiArICRyc3J2KXxvdXQtbnVsbDsNCiAgICANCiAgICAjZm9yY2libGUgcmVtb3ZlIHNlcnZlci9kb21haW4vdXNlciB2YXJpYWJsZXMgYW5kIGNvbnRlbnRzDQogICAgY2xlYXItaXRlbSB2YXJpYWJsZTpyc3J2IC1mb3JjZTsNCiAgICBjbGVhci1pdGVtIHZhcmlhYmxlOnJkb20gLWZvcmNlOw0KICAgIGNsZWFyLWl0ZW0gdmFyaWFibGU6cnVzciAtZm9yY2U7DQogICAgfQ0KDQojZm9yY2libHkgcmVtb3ZlIHJlbWFpbmluZyB2YXJpYWJsZXMgYW5kIGNvbnRlbnRzIGJlZm9yZSBmaW5pc2hpbmcuIw0KY2xlYXItaXRlbSB2YXJpYWJsZTpzZXJ2ZXJzIC1mb3JjZQ==";
                        string script = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(encscript));
                                                
                        if (!string.IsNullOrEmpty(extractFN))
                        {
                            System.IO.File.WriteAllText(extractFN, script);
                            return 0;
                        }

                        List<string> paramList = new List<string>(args);

                        powershell.AddScript(script);
                        powershell.AddParameters(paramList.GetRange(separator, paramList.Count - separator));
                        powershell.AddCommand("out-string");
                        powershell.AddParameter("-stream");


                        powershell.BeginInvoke<PSObject, PSObject>(inp, outp, null, new AsyncCallback(delegate(IAsyncResult ar)
                        {
                            if (ar.IsCompleted)
                                mre.Set();
                        }), null);

                        while (!me.ShouldExit && !mre.WaitOne(100))
                        {
                        };

                        powershell.Stop();
                    }

                    myRunSpace.Close();
                }
            }
            catch (Exception ex)
            {
                Console.Write("An exception occured: ");
                Console.WriteLine(ex.Message);
            }

            if (paramWait)
            {
                Console.WriteLine("Hit any key to exit...");
                Console.ReadKey();
            }
            return me.ExitCode;
        }


        static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            throw new Exception("Unhandeled exception in PS2EXE");
        }
    }
}