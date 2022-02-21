/* eslint-disable max-len */

import { useBackend } from '../backend';
import { Box, NumberInput, Button, ProgressBar, Section, Collapsible, LabeledList, Stack } from '../components';
import { Window } from '../layouts';
import { toFixed } from 'common/math';

const logScale = value => Math.log2(16 + Math.max(0, value)) - 4;

const HeaterDevices = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <>
      {data.heater_data.map(heater => (
        <Collapsible key={heater.ref} title={heater.name}>
          <Section title="Heater settings" buttons={(
            <Button
              icon={heater.on ? 'power-off' : 'times'}
              content={heater.on ? 'On' : 'Off'}
              selected={heater.on}
              onClick={() => act('heater_power', { "ref": heater.ref })} />
          )}>
            <LabeledList>
              <LabeledList.Item label="Current Temperature">
                <Box
                  fontSize="18px"
                  color={Math.abs(heater.targetTemp - heater.currentTemp) > 50
                    ? 'bad'
                    : Math.abs(heater.targetTemp - heater.currentTemp) > 20
                      ? 'average'
                      : 'good'}>
                  {heater.currentTemp}°C
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Target Temperature">
                <NumberInput
                  animated
                  value={parseFloat(heater.targetTemp)}
                  width="65px"
                  unit="°C"
                  minValue={heater.minTemp}
                  maxValue={heater.maxTemp}
                  onChange={(e, value) => act('heater_target', {
                    target: value,
                    "ref": heater.ref,
                  })} />
              </LabeledList.Item>
              <LabeledList.Item label="Mode">
                <Button
                  icon="thermometer-half"
                  content="Auto"
                  selected={heater.mode === 'auto'}
                  onClick={() => act('heater_mode', {
                    mode: "auto",
                    "ref": heater.ref,
                  })} />
                <Button
                  icon="fire-alt"
                  content="Heat"
                  selected={heater.mode === 'heat'}
                  onClick={() => act('heater_mode', {
                    mode: "heat",
                    "ref": heater.ref,
                  })} />
                <Button
                  icon="fan"
                  content="Cool"
                  selected={heater.mode === 'cool'}
                  onClick={() => act('heater_mode', {
                    mode: 'cool',
                    "ref": heater.ref,
                  })} />
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Collapsible>
      ))}
    </>
  );
};

const DischargerDevices = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <>
      {data.discharger_data.map(discharger => (
        <Collapsible key={discharger.ref} title={discharger.name}>
          <Section title="Discharger settings" buttons={(
            <Button
              icon={discharger.on ? 'power-off' : 'times'}
              content={discharger.on ? 'On' : 'Off'}
              selected={discharger.on}
              onClick={() => act('discharger_power', { "ref": discharger.ref })} />
          )}>
            <Box>
              Recently grounded {discharger.stored_power}.
            </Box>
          </Section>
        </Collapsible>
      ))}
    </>
  );
};

export const PenManager = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={600}
      height={600}>
      <Window.Content>
        <Section title="Creatures">
          {data.creature_data && (
            <>
              {data.creature_data.map(creature => (
                <Collapsible key={creature.name} title={creature.name}>
                  <Stack fill>
                    <Stack.Item grow>
                      <LabeledList>
                        <LabeledList.Item label="Health">
                          <ProgressBar
                            ranges={{
                              bad: [0, 40],
                              average: [40, 70],
                              good: [70, 100],
                            }}
                            value={creature.health}
                            minValue={-100}
                            maxValue={100}>
                            {toFixed(creature.health, 0.1) + ' %'}
                          </ProgressBar>
                        </LabeledList.Item>
                        {!!creature.is_slime && (
                          <LabeledList.Item label="Nutrition">
                            <ProgressBar
                              ranges={{
                                bad: [0, 40],
                                average: [40, 70],
                                good: [70, 100],
                              }}
                              value={creature.nutrition}
                              minValue={0}
                              maxValue={100}>
                              {toFixed(creature.nutrition, 0.1) + ' %'}
                            </ProgressBar>
                          </LabeledList.Item>
                        )}
                        {!!creature.is_slime && (
                          <LabeledList.Item label="Growth progress">
                            <ProgressBar
                              ranges={{
                                good: [0, 100],
                              }}
                              value={creature.growth}
                              minValue={0}
                              maxValue={100}>
                              {toFixed(creature.growth, 0.1) + ' %'}
                            </ProgressBar>
                          </LabeledList.Item>
                        )}
                      </LabeledList>
                    </Stack.Item>
                    <Stack.Divider mr={1} />
                    <Stack.Item grow>
                      <LabeledList>
                        <LabeledList.Item label="Status">
                          {creature.stat}
                        </LabeledList.Item>
                        {!!creature.cores && (
                          <LabeledList.Item label="Additional cores">
                            {creature.cores}
                          </LabeledList.Item>
                        )}
                        {!!creature.food_types && (
                          <LabeledList.Item label="Preferred food types">
                            {creature.food_types}.
                          </LabeledList.Item>
                        )}
                        {!!creature.environmental && (
                          <LabeledList.Item label="Environmental requirements">
                            {creature.environmental}
                          </LabeledList.Item>
                        )}
                      </LabeledList>
                    </Stack.Item>
                  </Stack>
                </Collapsible>
              ))}
            </>
          )}
        </Section>
        <Section title="Devices">
          {!!data.heater_data && (
            <HeaterDevices />
          )}
          {!!data.discharger_data && (
            <DischargerDevices />
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
