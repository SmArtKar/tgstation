import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  LabeledList,
  Modal,
  Section,
} from '../components';
import { Window } from '../layouts';

type HolocommsData = {
  calling: boolean;
  busy: boolean;
  nanotrasen_freq: boolean;
  can_request_ai: boolean;
  ai_cooldown_free: boolean;
  allowed: boolean;
  holo_calls: Holocall[];
};

type Holocall = {
  caller: string;
  answered: boolean;
  outgoing: boolean;
  target: string;
  call_ref: string;
};

export const Holocomms = (props) => {
  const { act, data } = useBackend<HolocommsData>();
  const { calling, busy } = data;
  return (
    <Window width={440} height={245}>
      {!!(calling || busy) && (
        <Modal fontSize="36px" fontFamily="monospace">
          <Flex align="center">
            <Flex.Item mr={2} mt={2}>
              <Icon name="phone-alt" rotation={25} />
            </Flex.Item>
            <Flex.Item mr={2}>{busy ? 'Occupied' : 'Dialing...'}</Flex.Item>
          </Flex>
          <Box mt={2} textAlign="center" fontSize="24px">
            <Button
              lineHeight="40px"
              icon="times"
              color="bad"
              onClick={() => act('hang_up')}
            >
              Hang Up
            </Button>
          </Box>
        </Modal>
      )}
      <Window.Content scrollable>
        <HolocommsContent />
      </Window.Content>
    </Window>
  );
};

const HolocommsContent = (props) => {
  const { act, data } = useBackend<HolocommsData>();
  const { can_request_ai, ai_cooldown_free, allowed, holo_calls } = data;
  return (
    <Section
      title="Holopad"
      buttons={
        can_request_ai && (
          <Button
            icon="bell"
            disabled={!ai_cooldown_free}
            onClick={() => act('ai_request')}
          >
            {ai_cooldown_free
              ? "Request AI's presence"
              : "AI's presence requested"}
          </Button>
        )
      }
    >
      <LabeledList>
        <LabeledList.Item label="Communicator">
          <Button
            icon="phone-alt"
            content={allowed ? 'Connect to Holopad' : 'Call Holopad'}
            onClick={() => act('holocall', { headcall: allowed })}
          />
        </LabeledList.Item>
        {holo_calls.map((call) => {
          return (
            <LabeledList.Item
              label={
                call.answered
                  ? 'Active Call'
                  : call.outgoing
                    ? 'Outgoing Call'
                    : 'Incoming Call'
              }
              key={call.call_ref}
            >
              <Button
                icon={call.answered ? 'phone-slash' : 'phone-alt'}
                color={call.answered || call.outgoing ? 'bad' : 'good'}
                onClick={() =>
                  act(
                    call.answered || call.outgoing
                      ? 'disconnectcall'
                      : 'connectcall',
                    {
                      holopad: call.call_ref,
                    },
                  )
                }
              >
                {call.answered
                  ? 'Disconnect call from ' + call.caller
                  : call.outgoing
                    ? 'Stop calling ' + call.target
                    : 'Answer call from ' + call.caller}
              </Button>
            </LabeledList.Item>
          );
        })}
        {holo_calls.filter((call) => !call.answered && !call.outgoing).length >
          0 && (
          <LabeledList.Item key="reject">
            <Button
              icon="phone-slash"
              color="bad"
              onClick={() => act('rejectcall')}
            >
              Reject incoming call
            </Button>
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};
