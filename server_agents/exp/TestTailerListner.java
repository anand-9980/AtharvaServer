
import java.io.File;

import org.apache.commons.io.input.Tailer;
import org.apache.commons.io.input.TailerListener;
import org.apache.commons.io.input.TailerListenerAdapter;

public class TestTailerListner extends TailerListenerAdapter {
	private static int LINE_NUMBER=1;
	
	@Override
	public void handle(String line) {
		System.out.println(line + "--> "+LINE_NUMBER);
		LINE_NUMBER++;
	}
	
	public static void main(String[] args) {
		System.out.println("Starting to tail -f ");
		TailerListener listener = new TestTailerListner();
		//String fileLocation = "/home/user/aanand1/expStrace/dev_agent_tracer/trace_pool/9_dummy_post_proc.txt";
		String fileLocation ="/home/user/aanand1/expStrace/dev_agent_tracer/exp/delTest.log";
		File file = new File(fileLocation);
		//Tailer tailer = Tailer.create(file, listener, 500);
		Tailer tailer = new Tailer(file, listener, 500);
		tailer.run();
		System.out.println("Done");
	}

}

