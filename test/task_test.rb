# frozen_string_literal: true

using_task_library "motors_yanmar_4lv150"
import_types_from "canbus"

describe OroGen.motors_yanmar_4lv150.Task do
    run_live

    attr_reader :task

    before do
        @task = syskit_deploy(
            OroGen.motors_yanmar_4lv150.Task
                  .deployed_as("task_under_test")
        )
        task.properties.source_address = 1
        syskit_configure_and_start(task)
    end

    it "updates the status only when all PGNs are received" do
        # All PGNS excepts 61444
        pgns = [61445, 65266, 65263, 65243, 65270, 65253, 65271, 65262]

        pgns.each do |pgn|
            msg = make_can_message(pgn, [0] * 8)
            syskit_write task.can_in_port, msg
        end

        expect_execution.to { have_no_new_sample task.status_port }

        # PGN 61444
        payload = [0x01, 175, 150, 0x40, 0x1F, 15, 0x03, 135]
        msg = make_can_message(0xF004, payload)

        sample = expect_execution { syskit_write task.can_in_port, msg }
                 .to { have_one_new_sample task.status_port }

        # Check all fields of EEC1
        assert_equal :ACCELERATOR_PEDAL, sample.engine_torque_mode
        assert_in_delta 0.50, sample.drivers_demand_engine_torque, 1e-3
        assert_in_delta 0.25, sample.actual_engine_torque, 1e-3
        assert_in_delta 104.71975, sample.engine_speed.speed, 1e-3
        assert_equal 15, sample.source_address
        assert_equal :START_FINISHED, sample.engine_starter_mode
        assert_in_delta 0.10, sample.engine_demand_torque, 1e-3

        assert_equal 61444, sample.last_received_pgn
        assert_equal (1 << 9) - 1, sample.received_messages
    end

    it "updates the alternator status from PGN 65271 (VEP)" do
        # PGN 65271
        payload = [0x7D, 0x32, 0xF0, 0x00, 0xFA, 0x00, 0x2C, 0x01]
        msg = make_can_message(0xFEF7, payload)

        alternator_sample = expect_execution { syskit_write task.can_in_port, msg }
            .to { have_one_new_sample(task.alternator_status_port) }

        assert_in_delta 12.0, alternator_sample.voltage, 1e-3
        assert_in_delta 50.0, alternator_sample.current, 1e-3
        assert_in_delta 130.0, alternator_sample.max_current, 1e-3
    end

    it "ignores messages from a different source address" do
        # PGN 65271, source address 2 (configured is 1)
        payload = [0x7D, 0x32, 0xF0, 0x00, 0xFA, 0x00, 0x2C, 0x01]
        msg = make_can_message(0xFEF7, payload, 2)

        expect_execution { syskit_write task.can_in_port, msg }
            .to { have_no_new_sample(task.alternator_status_port) }
    end

    def make_can_message(pgn, payload, source = 1)
        msg = Types.canbus.Message.new
        msg.time = Time.now
        # NMEA2000 / J1939 CAN ID:
        # Priority (3 bits) | PGN (18 bits) | Source (8 bits)
        msg.can_id = (3 << 26) | (pgn << 8) | source
        msg.size = payload.size
        payload.each_with_index { |v, i| msg.data[i] = v }
        msg
    end
end
