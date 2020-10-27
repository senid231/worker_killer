RSpec.describe WorkerKiller::Killer::Base do
  let(:logger){ Logger.new(nil) }
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.term_attempts = 2
    end
  end

  let(:killer){described_class.new(logger: logger)}

  describe '#kill' do
    context 'with use_quit TRUE' do
      around do |example|
        prev = WorkerKiller.configuration
        config.use_quit = true
        WorkerKiller.configuration = config
        example.run
      ensure
        WorkerKiller.configuration = prev
      end

      it 'expect right signal order' do
        expect(killer).to receive(:do_kill).with(:QUIT, anything, anything).exactly(2).times
        expect(killer).to receive(:do_kill).with(:TERM, anything, anything).exactly(2).times
        expect(killer).to receive(:do_kill).with(:KILL, anything, anything).exactly(5).times

        2.times { killer.kill(Time.now) } # 2 QUIT
        2.times { killer.kill(Time.now) } # 2 TERM
        5.times { killer.kill(Time.now) } # other - KILL
      end
    end

    context 'with use_quit FALSE' do
      around do |example|
        prev = WorkerKiller.configuration
        config.use_quit = false
        WorkerKiller.configuration = config
        example.run
      ensure
        WorkerKiller.configuration = prev
      end

      it 'expect right signal order' do
        expect(killer).to receive(:do_kill).with(:TERM, anything, anything).exactly(2).times
        expect(killer).to receive(:do_kill).with(:KILL, anything, anything).exactly(5).times

        2.times { killer.kill(Time.now) } # 2 TERM
        5.times { killer.kill(Time.now) } # other - KILL
      end
    end
  end
end

