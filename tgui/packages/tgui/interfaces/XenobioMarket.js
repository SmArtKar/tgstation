/* eslint-disable max-len */

import { useBackend, useLocalState } from '../backend';
import { Box, LabeledList, Section, Stack, Table, Tabs, Button } from '../components';
import { Window } from '../layouts';
import { classes } from 'common/react';

const logScale = value => Math.log2(16 + Math.max(0, value)) - 4;


const SlimeMarket = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Table>
      {data.prices.map(price_row => (
        <Table.Row key={price_row.key}>
          {price_row.prices.map(slime_price => (
            <Table.Cell width="25%" key={slime_price.key}>
              {!!slime_price.price && (
                <Section style={{ "border-radius": "5px" }} mb="6px">
                  <Stack fill>
                    <Stack.Item>
                      <Box className={classes([
                        'xenobio_market32x32',
                        slime_price.icon,
                      ])} />
                    </Stack.Item>
                    <Stack.Item mt="10px">
                      Currect price: {slime_price.price} points.
                    </Stack.Item>
                  </Stack>
                </Section>
              )}
            </Table.Cell>
          ))}
        </Table.Row>
      ))}
    </Table>
  );
};

const IntergalacticBounties = (props, context) => {
  const { act, data } = useBackend(context);
  const [selectedCompany, setSelectedCompany] = useLocalState(context, 'selectedCompany', "Xynergy Solutions");
  const { companies_by_name = [] } = data;
  return (
    <Stack grow>
      <Stack.Item>
        <Stack vertical>
          <Stack.Item>
            <Tabs vertical fill style={{ "border-radius": "5px" }}>
              {data.companies.map(company => (
                <Tabs.Tab
                  key={company.name}
                  selected={selectedCompany === company.name}
                  icon={company.icon}
                  onClick={() => setSelectedCompany(company.name)}>
                  {company.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item>
            <Section title="Current Bounty" style={{ "border-radius": "5px" }} width="100%">
              <LabeledList vertical>
                {!!data.current_bounty && (
                  <>
                    <LabeledList.Item label="Requirements">
                      {data.current_bounty.text_requirements}
                    </LabeledList.Item>
                    <LabeledList.Item label="Rewards">
                      {data.current_bounty.text_rewards}
                    </LabeledList.Item>
                    <LabeledList.Item label="Requested by">
                      {data.current_bounty.author_name}
                    </LabeledList.Item>
                  </>
                ) || (
                  <Box fontSize="18px" ml="8px">
                    No bounty selected.
                  </Box>
                )}
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow>
        <Stack vertical grow>
          <Stack.Item>
            <Section title={selectedCompany} grow>
              <Box mb="6px">
                {companies_by_name[selectedCompany].desc}
              </Box>
              <LabeledList vertical>
                <LabeledList.Item label="Maximum Bounty Level">
                  {companies_by_name[selectedCompany].relationship}
                </LabeledList.Item>
                <LabeledList.Item label="Finished Bounties">
                  {companies_by_name[selectedCompany].bounties_finished}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          {!!companies_by_name[selectedCompany] && (
            <Stack.Item grow>
              <Table>
                {companies_by_name[selectedCompany].bounties.map(bounty_row => (
                  <Table.Row key={bounty_row.iter}>
                    {data.bounty_row.bounties.map(bounty => (
                      <Table.Cell key={bounty.name}>
                        <Section title={bounty.name} mb="6px">
                          <LabeledList vertical>
                            <LabeledList.Item label="Requirements">
                              {bounty.text_requirements}
                            </LabeledList.Item>
                            <LabeledList.Item label="Rewards">
                              {bounty.text_rewards}
                            </LabeledList.Item>
                          </LabeledList>
                          <Button mt="6px" ml="40%"
                            width="20%" textAlign="center"
                            disabled={bounty.ref === current_bounty.ref}
                            onClick={() => act('selected_bounty', {
                              "ref": bounty.ref,
                            })} >
                            Take Bounty
                          </Button>
                        </Section>
                      </Table.Cell>
                    ))}
                  </Table.Row>
                ))}
              </Table>
            </Stack.Item>
          )}
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

export const XenobioMarket = (props, context) => {
  const { act, data } = useBackend(context);
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 1);
  return (
    <Window
      width={tabIndex === 1 && 900 || 680}
      height={tabIndex === 1 && 412 || 500}>
      <Window.Content>
        <Tabs style={{ "border-radius": "5px" }}>
          <Tabs.Tab
            key={1}
            selected={tabIndex === 1}
            icon="flask"
            onClick={() => setTabIndex(1)}>
            Slime Market
          </Tabs.Tab>
          <Tabs.Tab
            key={2}
            selected={tabIndex === 2}
            icon="globe"
            onClick={() => setTabIndex(2)}>
            Intergalactic Bounties
          </Tabs.Tab>
          <Tabs.Tab
            key={3}
            selected={tabIndex === 3}
            icon="rocket"
            onClick={() => setTabIndex(3)}>
            Station Bounties
          </Tabs.Tab>
        </Tabs>
        <Box>
          {tabIndex === 1 && (
            <SlimeMarket />
          )}
          {tabIndex === 2 && (
            <IntergalacticBounties />
          )}
        </Box>
      </Window.Content>
    </Window>
  );
};
